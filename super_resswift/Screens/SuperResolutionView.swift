import SwiftUI
import PhotosUI

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
    @State private var showSaveAlert = false
    @State private var saveMessage = ""

    private let runner = SRRunner()
    private let tiler = SRTiler()
    private let photoSaver = PhotoSaver()
    private var modelAvailable: Bool { SRRunner.isModelAvailableInBundle() }

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                ImagePane(leftTitle: "Original Image",
                          rightTitle: "Upscaled Image",
                          left: inputImage,
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

            LoadingOverlay(running: running, message: progressText)
        }
        .navigationTitle("超解像")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    guard let out = outputImage else { return }
                    photoSaver.completion = { error in
                        DispatchQueue.main.async {
                            if let error {
                                saveMessage = "保存に失敗しました: \(error.localizedDescription)"
                            } else {
                                saveMessage = "写真に保存しました"
                            }
                            showSaveAlert = true
                        }
                    }
                    photoSaver.save(out)
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
    }

    private func runInference() {
        guard let ui = inputImage, let cg = ImageIOUtil.cgImage(from: ui) else { return }
        running = true
        errorMessage = ""; progressText = ""
        Task {
            do {
                // 将来的にタイル経路に切替可能
                let outCG = try await runner.upscale(cg)
                // 元画像の向き・スケールを維持して生成
                let outUI = UIImage(cgImage: outCG, scale: ui.scale, orientation: ui.imageOrientation)
                await MainActor.run { self.outputImage = outUI }
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
            await MainActor.run { self.running = false }
        }
    }
}

// MARK: - Photo Saving Helper
final class PhotoSaver: NSObject {
    var completion: ((Error?) -> Void)?

    func save(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(didFinishSaving(_:didFinishSavingWithError:contextInfo:)), nil)
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
