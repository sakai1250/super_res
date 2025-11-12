import SwiftUI
import PhotosUI
import Photos

// 元Flutter: lib/screens/super_resolution_screen.dart
// - 進捗/エラー表示
// - 左右パネル（Original / Upscaled）
// - 「超解像を実行」ボタンで推論トリガー
// - 保存（右上）: UIImageWriteToSavedPhotosAlbum

struct SuperResolutionView: View {
    let inputImage: UIImage?
    var onSaveOutput: (UIImage?) -> Void

    @State private var running = false
    @State private var errorMessage = ""
    @State private var outputImage: UIImage?
    @State private var progressText = ""
    @State private var progress: Double? = nil
    @State private var showSaveAlert = false
    @State private var saveMessage = ""
    @State private var didAutoSave = false
    @State private var originalImage: UIImage? = nil

    private let runner = SRRunner()
    private let tiler = SRTiler()
    private let photoSaver = PhotoSaver()
    private var modelAvailable: Bool { SRRunner.isModelAvailableInBundle() }

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                ImagePane(leftTitle: "Original Image",
                          rightTitle: "Upscaled Image",
                          left: originalImage ?? inputImage,
                          right: outputImage)
                    .frame(height: 420)
                    .padding(.horizontal)

                // 解像度の確認用ラベル（px）
                HStack(spacing: 12) {
                    Text("Orig: \(pixelSizeString(inputImage))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("→")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Out: \(pixelSizeString(outputImage))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button("超解像を実行") { runInference() }
                    .buttonStyle(.borderedProminent)
                    .disabled(running || inputImage == nil)

                if !modelAvailable {
                    Text("注意: 超解像モデルが同梱されていないため、簡易拡大(Lanczos)で代替します")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage).foregroundColor(.red).font(.footnote)
                }

                Spacer()
            }

            LoadingOverlay(running: running, message: progressText, progress: progress)
        }
        .navigationTitle("超解像")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    guard let out = outputImage else { return }
                    // 親（メモ）に適用のみ。保存は自動保存に任せる。
                    onSaveOutput(out)
                } label: { Image(systemName: "square.and.arrow.down") }
                .disabled(outputImage == nil)
            }
        }
        .alert("保存", isPresented: $showSaveAlert) {
            Button("OK") {}
        } message: {
            Text(saveMessage)
        }
        .onAppear {
            if originalImage == nil { originalImage = inputImage }
        }
    }

    private func runInference() {
        guard let ui = inputImage, let cg = ImageIOUtil.cgImage(from: ui) else { return }
        running = true
        errorMessage = ""
        progressText = "準備中…"
        progress = 0.05
        Task {
            do {
                // 画像が大きい場合はタイル推論
                let useTile = max(cg.width, cg.height) > 1024 && modelAvailable
                progressText = useTile ? "タイル推論中…" : "推論中…"
                progress = useTile ? 0.4 : 0.6
                let outCG: CGImage
                if useTile {
                    let cfg = TileConfig(tile: 256, overlap: 16, scale: 4)
                    outCG = try await tiler.upscaleTiled(cg, cfg: cfg) { p in
                        DispatchQueue.main.async { self.progress = 0.4 + 0.45 * p }
                    }
                } else {
                    outCG = try await runner.upscale(cg)
                }
                // 元画像の向き・スケールを維持して生成
                let outUI = UIImage(cgImage: outCG, scale: ui.scale, orientation: ui.imageOrientation)
                await MainActor.run {
                    self.progressText = "後処理…"
                    self.progress = 0.9
                    self.outputImage = outUI
                    self.photoSaver.completion = { error in
                        DispatchQueue.main.async {
                            if let error {
                                self.saveMessage = "保存に失敗しました: \(error.localizedDescription)"
                            } else {
                                self.saveMessage = "写真に保存しました"
                                self.didAutoSave = true
                            }
                            self.showSaveAlert = true
                        }
                    }
                    self.photoSaver.save(outUI)
                    self.progress = 1.0
                }
            } catch {
                let msg: String
                if let srErr = error as? SRRunnerError {
                    switch srErr {
                    case .modelNotFound:
                        msg = "超解像モデルが見つかりませんでした"
                    case .conversionFailed:
                        msg = "推論結果の画像化に失敗しました"
                    }
                } else {
                    msg = "超解像に失敗しました: \(error.localizedDescription)"
                }
                await MainActor.run { self.errorMessage = msg }
            }
            await MainActor.run {
                self.running = false
                self.progress = nil
            }
        }
    }
}

// MARK: - Photo Saving Helper
final class PhotoSaver: NSObject {
    var completion: ((Error?) -> Void)?

    func save(_ image: UIImage) {
        #if targetEnvironment(macCatalyst)
        completion?(NSError(domain: "PhotoSaver", code: 1, userInfo: [NSLocalizedDescriptionKey: "macOSでは写真保存は未対応です"]))
        return
        #else
        if #available(iOS 14, *) {
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            switch status {
            case .authorized, .limited:
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(didFinishSaving(_:didFinishSavingWithError:contextInfo:)), nil)
            case .notDetermined:
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { _ in
                    DispatchQueue.main.async {
                        UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.didFinishSaving(_:didFinishSavingWithError:contextInfo:)), nil)
                    }
                }
            default:
                self.completion?(NSError(domain: "PhotoSaver", code: 2, userInfo: [NSLocalizedDescriptionKey: "写真保存の許可がありません"]))
            }
        } else {
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(didFinishSaving(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        #endif
    }

    @objc private func didFinishSaving(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeMutableRawPointer?) {
        completion?(error)
    }
}

// MARK: - Helpers
private func pixelSizeString(_ img: UIImage?) -> String {
    guard let img else { return "-" }
    if let cg = ImageIOUtil.cgImage(from: img) {
        return "\(cg.width)x\(cg.height) px"
    }
    // フォールバック: ポイント×scale
    let w = Int(img.size.width * img.scale)
    let h = Int(img.size.height * img.scale)
    return "\(w)x\(h) px"
}
