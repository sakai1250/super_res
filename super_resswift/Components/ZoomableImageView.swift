import SwiftUI

// ピンチズーム + ドラッグでパン可能な画像ビュー
struct ZoomableImageView: View {
    let image: UIImage
    var maxScale: CGFloat = 4.0

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            Image(uiImage: image)
                .resizable()
                .scaledToFit() // 初期表示は枠にフィット
                .frame(width: geo.size.width, height: geo.size.height)
                .scaleEffect(scale, anchor: .center)
                .offset(x: offset.width, y: offset.height)
                .contentShape(Rectangle())
                .gesture(dragGesture(container: geo.size))
                .simultaneousGesture(magnificationGesture(container: geo.size))
                .simultaneousGesture(doubleTapResetGesture())
                .animation(.easeInOut(duration: 0.12), value: scale)
                .animation(.easeInOut(duration: 0.12), value: offset)
        }
    }

    // MARK: - Gestures
    private func magnificationGesture(container: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = clampScale(lastScale * value)
                scale = newScale
                if newScale <= 1.0 {
                    offset = .zero
                } else {
                    offset = clampedOffset(for: container, proposed: lastOffset)
                }
            }
            .onEnded { value in
                lastScale = clampScale(lastScale * value)
                if lastScale <= 1.0 { resetTransform(animated: true) }
                lastOffset = offset
            }
    }

    private func dragGesture(container: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1.0 else { return }
                let proposed = CGSize(width: lastOffset.width + value.translation.width,
                                      height: lastOffset.height + value.translation.height)
                offset = clampedOffset(for: container, proposed: proposed)
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func doubleTapResetGesture() -> some Gesture {
        TapGesture(count: 2).onEnded { resetTransform(animated: true) }
    }

    // MARK: - Helpers
    private func clampScale(_ s: CGFloat) -> CGFloat { min(max(1.0, s), maxScale) }

    private func clampedOffset(for container: CGSize, proposed: CGSize) -> CGSize {
        guard scale > 1.0 else { return .zero }
        // 拡大後のコンテンツサイズ（scaledToFit -> 片方はちょうど、もう片方はレター）を概算
        // ここでは保守的にコンテナサイズ×scaleで上限を算出
        let contentW = container.width * scale
        let contentH = container.height * scale
        let maxX = max(0, (contentW - container.width) / 2)
        let maxY = max(0, (contentH - container.height) / 2)
        let clampedX = min(max(-maxX, proposed.width), maxX)
        let clampedY = min(max(-maxY, proposed.height), maxY)
        return CGSize(width: clampedX, height: clampedY)
    }

    private func resetTransform(animated: Bool) {
        lastScale = 1.0
        lastOffset = .zero
        if animated {
            withAnimation { scale = 1.0; offset = .zero }
        } else {
            scale = 1.0; offset = .zero
        }
    }
}

