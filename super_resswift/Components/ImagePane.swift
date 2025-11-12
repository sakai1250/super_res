import SwiftUI

// 元Flutter: lib/screens/super_resolution_screen.dart の左右比較レイアウト
struct ImagePane: View {
    let leftTitle: String
    let rightTitle: String
    let left: UIImage?
    let right: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            pane(title: leftTitle, image: left)
            pane(title: rightTitle, image: right)
        }
    }

    private func pane(title: String, image: UIImage?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
            GeometryReader { geo in
                ZStack {
                    if let img = image {
                        ZoomableImageView(image: img)
                            .frame(width: geo.size.width, height: geo.size.height)
                    } else {
                        Rectangle().fill(Color(uiColor: .systemGray5))
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
            }
        }
    }
}
