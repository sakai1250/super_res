import CoreGraphics
import Foundation

// 大画像用タイル推論
struct TileConfig {
    let tile: Int      // 入力タイル辺サイズ（px）
    let overlap: Int   // 入力側の重なり幅（px）
    let scale: Int     // モデルの拡大率（例: x4）
}

struct SRTiler {
    // 実タイル推論（決定的な進捗を返す）
    func upscaleTiled(_ cg: CGImage, cfg: TileConfig, progress: ((Double) -> Void)? = nil) async throws -> CGImage {
        let runner = SRRunner()

        let width = cg.width
        let height = cg.height
        let tile = max(32, cfg.tile)
        let overlap = max(0, cfg.overlap)
        let scale = max(1, cfg.scale)

        // 出力キャンバス
        let outW = width * scale
        let outH = height * scale
        guard let colorSpace = cg.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB) else { return cg }
        guard let ctx = CGContext(data: nil,
                                  width: outW,
                                  height: outH,
                                  bitsPerComponent: cg.bitsPerComponent,
                                  bytesPerRow: 0,
                                  space: colorSpace,
                                  bitmapInfo: cg.bitmapInfo.rawValue) else { return cg }

        // グリッド走査数の概算（進捗用）
        let xSteps = Int(ceil(Double(width) / Double(tile)))
        let ySteps = Int(ceil(Double(height) / Double(tile)))
        let total = max(1, xSteps * ySteps)
        var done = 0

        for ty in stride(from: 0, to: height, by: tile) {
            for tx in stride(from: 0, to: width, by: tile) {
                // 入力タイル領域（オーバーラップ付きソース矩形）
                let srcX = max(0, tx - overlap)
                let srcY = max(0, ty - overlap)
                let srcW = min(width - srcX, tile + overlap + max(0, min(overlap, tx + tile + overlap - width)))
                let srcH = min(height - srcY, tile + overlap + max(0, min(overlap, ty + tile + overlap - height)))
                let srcRect = CGRect(x: srcX, y: srcY, width: srcW, height: srcH)

                guard let tileCG = cg.cropping(to: srcRect) else { continue }

                // タイルを推論（拡大）
                let upCG = try await runner.upscale(tileCG)

                // 出力へ貼り付ける中心領域（オーバーラップを除いた実タイル領域）
                let coreX = tx
                let coreY = ty
                let coreW = min(tile, width - tx)
                let coreH = min(tile, height - ty)
                let coreRectInInput = CGRect(x: coreX, y: coreY, width: coreW, height: coreH)

                // オーバーラップ付きソース内でのコア領域の位置
                let coreInSrc = coreRectInInput.offsetBy(dx: -srcRect.origin.x, dy: -srcRect.origin.y)

                // 上記を拡大後座標に変換
                let srcCropInUpscaled = CGRect(x: Int(coreInSrc.origin.x) * scale,
                                               y: Int(coreInSrc.origin.y) * scale,
                                               width: Int(coreInSrc.size.width) * scale,
                                               height: Int(coreInSrc.size.height) * scale)

                // アップスケール画像から必要部分を切り出し
                guard let croppedUp = upCG.cropping(to: srcCropInUpscaled) else { continue }

                // 出力先座標（拡大先キャンバス）
                let dstRect = CGRect(x: coreRectInInput.origin.x * CGFloat(scale),
                                     y: coreRectInInput.origin.y * CGFloat(scale),
                                     width: coreRectInInput.size.width * CGFloat(scale),
                                     height: coreRectInInput.size.height * CGFloat(scale))

                ctx.draw(croppedUp, in: dstRect)

                done += 1
                progress?(Double(done) / Double(total))
            }
        }

        return ctx.makeImage() ?? cg
    }
}
