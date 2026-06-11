import SwiftUI
import WebKit

/// Shared web panel: serves both the fullscreen launch gate and the
/// Settings -> Privacy Policy sheet.
struct DungeonArchitectWebPanel: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        // Belt-and-suspenders; the presenting frame respecting the top safe
        // area is the real guarantee. NEVER .never.
        webView.scrollView.contentInsetAdjustmentBehavior = .always
        webView.isOpaque = true
        webView.backgroundColor = .black
        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    // MUST stay empty — reloading here would loop on every SwiftUI re-render.
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

/// Splash shown while the launch link check runs.
struct DungeonArchitectLoadingScreen: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            DATheme.obsidian.edgesIgnoringSafeArea(.all)
            RadialGradient(colors: [DATheme.plumDeep, DATheme.obsidian],
                           center: .center, startRadius: 40, endRadius: 360)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 26) {
                HeartCrystalIcon(size: 84, color: DATheme.blood)
                    .scaleEffect(pulse ? 1.1 : 0.92)
                    .shadow(color: DATheme.blood.opacity(0.6), radius: pulse ? 26 : 10)
                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)

                Text("Dungeon Architect")
                    .font(DATheme.display(28))
                    .foregroundColor(DATheme.bone)

                Text("The Heart awakens...")
                    .font(DATheme.ui(14, .medium))
                    .foregroundColor(DATheme.boneDim)
            }
        }
        .onAppear { pulse = true }
    }
}
