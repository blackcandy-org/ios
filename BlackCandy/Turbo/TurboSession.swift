import WebKit
import ComposableArchitecture
import Turbo

struct TurboSession {
  static let processPool = WKProcessPool()

  static func create(store: StoreOf<AppReducer>) -> Session {
    let configuration = WKWebViewConfiguration()
    let scriptMessageHandler = TurboScriptMessageHandler(store: store)
    let pathConfiguration = PathConfiguration(sources: [
      .file(Bundle.main.url(forResource: "path-configuration", withExtension: "json")!)
    ])

    configuration.applicationNameForUserAgent = BLACK_CANDY_USER_AGENT
    configuration.processPool = TurboSession.processPool
    configuration.userContentController.add(scriptMessageHandler, name: "nativeApp")

    // Set the webview frame more than zero to avoid logs of `maximumViewportInset cannot be larger than frame`
    let webView = WKWebView(
      frame: CGRect(x: 0.0, y: 0.0, width: 0.1, height: 0.1),
      configuration: configuration
    )

    webView.allowsLinkPreview = false

    let session = Session(webView: webView)
    session.pathConfiguration = pathConfiguration

    return session
  }
}
