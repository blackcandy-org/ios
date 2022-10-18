import Foundation
import WebKit
import ComposableArchitecture

class TurboScriptMessageHandler: NSObject, WKScriptMessageHandler {
  let viewStore = ViewStore(AppStore.shared.stateless, removeDuplicates: ==)

  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    guard let body = message.body as? [String: Any],
      let actionName = body["name"] as? String else { return }

    switch actionName {
    case "playAll":
      viewStore.send(.player(.playAll))
    default:
      return
    }
  }
}
