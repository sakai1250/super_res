import SwiftUI

// 処理中オーバーレイ
struct LoadingOverlay: View {
    let running: Bool
    var message: String? = nil

    var body: some View {
        if running {
            ZStack {
                Color.black.opacity(0.25).ignoresSafeArea()
                VStack(spacing: 12) {
                    ProgressView()
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

