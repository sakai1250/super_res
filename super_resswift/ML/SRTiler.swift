import CoreGraphics
import Foundation

// 大画像用タイル推論の骨組み
struct TileConfig {
    let tile: Int
    let overlap: Int
    let scale: Int
}

struct SRTiler {
    func upscaleTiled(_ cg: CGImage, cfg: TileConfig) throws -> CGImage {
        // 最小実装（今はタイル分割せず直接呼ぶ）
        // 将来: cg を tile×tile へ分割し、overlap 分重ねて結合
        let runner = SRRunner()
        var out: CGImage?
        let sem = DispatchSemaphore(value: 0)
        Task {
            out = try? await runner.upscale(cg)
            sem.signal()
        }
        sem.wait()
        return out ?? cg
    }
}

