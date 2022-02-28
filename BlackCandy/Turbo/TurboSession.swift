import WebKit
import Turbo

struct TurboSession {
  static let processPool = WKProcessPool()

  static func create() -> Session {
    let configuration = WKWebViewConfiguration()
    configuration.applicationNameForUserAgent = "Turbo Native iOS"
    configuration.processPool = TurboSession.processPool

    return Session(webViewConfiguration: configuration)
  }
}
