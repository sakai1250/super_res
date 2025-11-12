import SwiftUI

// 処理中オーバーレイ
struct LoadingOverlay: View {
    let running: Bool
    var message: String? = nil
    var progress: Double? = nil // 0.0...1.0（nilなら不定）

    var body: some View {
        if running {
            ZStack {
                Color.black.opacity(0.25).ignoresSafeArea()
                VStack(spacing: 12) {
                    if let p = progress {
                        ProgressView(value: p)
                            .progressViewStyle(.linear)
                            .frame(width: 220)
                    } else {
                        ProgressView()
                    }
                    if let message { Text(message).font(.footnote).foregroundColor(.white) }
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
            .transition(.opacity)
        }
    }
}
