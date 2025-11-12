import Foundation
import CoreML
import Vision
import UIKit
import CoreImage
import Accelerate

// Core ML呼び出しスタブ
// 前提モデル名: RealESRGAN_x4.mlmodel
// FIXME: replace with generated class (e.g., RealESRGAN_x4)

enum SRRunnerError: Error { case modelNotFound, conversionFailed }

final class SRRunner {
    private var model: MLModel?
    private static var cachedModel: MLModel?
    var hasModel: Bool { model != nil }

    init() {
        // バンドルから .mlmodelc / .mlmodel を探索してロード
        if let m = Self.cachedModel {
            self.model = m
        } else if let m = try? SRRunner.loadCompiledModel() {
            Self.cachedModel = m
            self.model = m
        }
    }

    static func loadCompiledModel() throws -> MLModel {
        let config = MLModelConfiguration()
        config.computeUnits = .all

        // 1) 生成済みクラスがある場合はここで差し替えて即return
        // 例:
        // let mdl = try RealESRGAN_x4(configuration: config).model
        // return mdl

        // 2) バンドル内の .mlmodelc / .mlmodel を探索
        let bundle = Bundle.main
        if let urls = bundle.urls(forResourcesWithExtension: "mlmodelc", subdirectory: nil), let url = urls.first {
            return try MLModel(contentsOf: url, configuration: config)
        }
        if let urls = bundle.urls(forResourcesWithExtension: "mlmodel", subdirectory: nil), let url = urls.first {
            let compiled = try MLModel.compileModel(at: url)
            return try MLModel(contentsOf: compiled, configuration: config)
        }

        throw SRRunnerError.modelNotFound
    }

    func upscale(_ input: CGImage) async throws -> CGImage {
        // 1) 実モデルがあれば Vision 経由で推論
        if let model {
            let vnModel = try VNCoreMLModel(for: model)
            if let imageKey = model.modelDescription.inputDescriptionsByName.first?.key {
                vnModel.inputImageFeatureName = imageKey
            }
            let request = VNCoreMLRequest(model: vnModel)
            request.imageCropAndScaleOption = .scaleFit

            let handler = VNImageRequestHandler(cgImage: input, options: [:])
            var outputCG: CGImage?
            try handler.perform([request])

            if let results = request.results {
                // 画像出力のケース
                if let pix = (results as? [VNPixelBufferObservation])?.first?.pixelBuffer {
                    outputCG = SRRunner.cgImage(from: pix)
                } else if let fv = (results as? [VNCoreMLFeatureValueObservation])?.first?.featureValue {
                    if let pb = fv.imageBufferValue {
                        outputCG = SRRunner.cgImage(from: pb)
                    } else if let ma = fv.multiArrayValue {
                        outputCG = SRRunner.cgImage(from: ma)
                    }
                }
            }

            if let outputCG { return outputCG }
            throw SRRunnerError.conversionFailed
        }

        // 2) モデル未配置時は簡易フォールバック（2倍Lanczos）
        // TestFlight/Release でもエラーで止めず、最低限の拡大を返す。
        if let cg = Self.fallbackLanczosScale(input, scale: 2.0) { return cg }
        return input
    }

    // MARK: - Converters
    private static func cgImage(from pixelBuffer: CVPixelBuffer) -> CGImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        let rect = CGRect(x: 0, y: 0, width: ciImage.extent.width, height: ciImage.extent.height)
        return context.createCGImage(ciImage, from: rect)
    }

    private static func cgImage(from multiArray: MLMultiArray) -> CGImage? {
        // 想定形状: (H,W,3) もしくは (3,H,W)
        let shape = multiArray.shape.map { Int(truncating: $0) }
        guard shape.count == 3 else { return nil }

        let isCHW = shape[0] == 3
        let height = isCHW ? shape[1] : shape[0]
        let width  = isCHW ? shape[2] : shape[1]
        let channels = 3

        // Float32 前提で取り出し（異なる場合は変換）
        let floatPtr: UnsafeMutablePointer<Float>
        let count = width * height * channels
        var buffer = [Float](repeating: 0, count: count)

        switch multiArray.dataType {
        case .float32:
            floatPtr = UnsafeMutablePointer<Float>(OpaquePointer(multiArray.dataPointer))
            if isCHW {
                // 転置: [3,H,W] -> [H,W,3]
                for c in 0..<channels {
                    for y in 0..<height {
                        for x in 0..<width {
                            let src = c * height * width + y * width + x
                            let dst = (y * width + x) * channels + c
                            buffer[dst] = floatPtr[src]
                        }
                    }
                }
            } else {
                // 既に [H,W,3]
                memcpy(&buffer, floatPtr, count * MemoryLayout<Float>.size)
            }
        default:
            return nil
        }

        // 0..1 または -1..1 を 0..255 へ
        var minVal: Float = -1, maxVal: Float = 1
        vDSP_minv(buffer, 1, &minVal, vDSP_Length(count))
        vDSP_maxv(buffer, 1, &maxVal, vDSP_Length(count))
        var scale: Float = 255.0 / max(1e-6, maxVal - minVal)
        var bias: Float = -minVal * scale
        var u8 = [UInt8](repeating: 0, count: count)
        vDSP_vsmsa(buffer, 1, &scale, &bias, &buffer, 1, vDSP_Length(count))
        var f = buffer // copy
        vDSP_vfixu8(f, 1, &u8, 1, vDSP_Length(count))

        // CGImage 生成
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let bytesPerRow = width * channels
        let byteCount = u8.count
        return u8.withUnsafeBytes { raw in
            let ptr = raw.bindMemory(to: UInt8.self).baseAddress!
            guard let cfData = CFDataCreate(kCFAllocatorDefault, ptr, byteCount) else { return nil }
            guard let dataProvider = CGDataProvider(data: cfData) else { return nil }
            return CGImage(width: width,
                           height: height,
                           bitsPerComponent: 8,
                           bitsPerPixel: 8 * channels,
                           bytesPerRow: bytesPerRow,
                           space: colorSpace,
                           bitmapInfo: CGBitmapInfo.byteOrderDefault.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)),
                           provider: dataProvider,
                           decode: nil,
                           shouldInterpolate: false,
                           intent: .defaultIntent)
        }
    }
}

// MARK: - Helpers
extension SRRunner {
    static func isModelAvailableInBundle() -> Bool {
        let bundle = Bundle.main
        if let urls = bundle.urls(forResourcesWithExtension: "mlmodelc", subdirectory: nil), !urls.isEmpty { return true }
        if let urls = bundle.urls(forResourcesWithExtension: "mlmodel", subdirectory: nil), !urls.isEmpty { return true }
        return false
    }

    static func fallbackLanczosScale(_ input: CGImage, scale: CGFloat) -> CGImage? {
        let ci = CIImage(cgImage: input)
        guard let filter = CIFilter(name: "CILanczosScaleTransform") else { return nil }
        filter.setValue(ci, forKey: kCIInputImageKey)
        filter.setValue(scale, forKey: kCIInputScaleKey)
        filter.setValue(1.0, forKey: kCIInputAspectRatioKey)
        let context = CIContext(options: nil)
        let outputCI = filter.outputImage ?? ci
        let rect = CGRect(x: 0, y: 0, width: CGFloat(input.width) * scale, height: CGFloat(input.height) * scale)
        return context.createCGImage(outputCI, from: rect)
    }
}
