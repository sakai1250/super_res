import UIKit
import CoreVideo
import CoreImage

enum ImageIOUtil {
    static func uiImage(from cg: CGImage) -> UIImage { UIImage(cgImage: cg) }

    static func cgImage(from ui: UIImage) -> CGImage? {
        if let cg = ui.cgImage { return cg }
        if let ci = ui.ciImage {
            let ctx = CIContext(options: nil)
            return ctx.createCGImage(ci, from: ci.extent)
        }
        return nil
    }
}

