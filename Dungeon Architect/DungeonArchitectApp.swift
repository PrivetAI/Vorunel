import SwiftUI

@main
struct DungeonArchitectApp: App {
    @State private var architectLinkReady: Bool? = nil

    private let architectSourceLink = "https://example.com"
    private let architectCheckDomain = "example"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = architectLinkReady {
                    if ready {
                        // Fullscreen web panel — the FRAME respects the top safe area
                        // (notch / Dynamic Island); contentInset alone is not reliable.
                        DungeonArchitectWebPanel(urlString: architectSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        RootView()
                    }
                } else {
                    DungeonArchitectLoadingScreen()
                        .onAppear { probeArchitectLink() }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func probeArchitectLink() {
        guard let url = URL(string: architectSourceLink) else {
            architectLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = ArchitectRedirectTracker(checkDomain: architectCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    architectLinkReady = false
                    return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(architectCheckDomain) {
                    architectLinkReady = false
                    return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(architectCheckDomain) {
                    architectLinkReady = false
                    return
                }
                if error != nil {
                    architectLinkReady = false
                    return
                }
                architectLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if architectLinkReady == nil { architectLinkReady = false }
        }
    }
}

/// Follows every redirect, never stops the chain, and remembers whether the
/// check domain appeared anywhere along the way.
final class ArchitectRedirectTracker: NSObject, URLSessionTaskDelegate {
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
