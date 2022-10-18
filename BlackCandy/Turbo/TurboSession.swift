import WebKit
import Turbo

struct TurboSession {
  static let processPool = WKProcessPool()

  static func create() -> Session {
    let configuration = WKWebViewConfiguration()
    let scriptMessageHandler = TurboScriptMessageHandler()

    configuration.applicationNameForUserAgent = "Turbo Native iOS"
    configuration.processPool = TurboSession.processPool
    configuration.userContentController.add(scriptMessageHandler, name: "nativeApp")

    // Set the webview frame more than zero to avoid logs of `maximumViewportInset cannot be larger than frame`
    let webView = WKWebView(
      frame: CGRect(x: 0.0, y: 0.0, width: 0.1, height: 0.1),
      configuration: configuration
    )

    return Session(webView: webView)
  }
}
