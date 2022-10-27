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
    case "playSong":
      guard let songId = body["songId"] as? Int else { return }
      viewStore.send(.player(.playSong(songId)))
    case "updateTheme":
      guard
        let theme = body["theme"] as? String,
        let currentTheme = AppState.Theme(rawValue: theme) else { return }

      viewStore.send(.updateTheme(currentTheme))
    default:
      return
    }
  }
}
