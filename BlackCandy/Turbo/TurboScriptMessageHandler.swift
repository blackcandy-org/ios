import Foundation
import WebKit
import ComposableArchitecture

class TurboScriptMessageHandler: NSObject, WKScriptMessageHandler {
  let store: StoreOf<AppReducer>

  init(store: StoreOf<AppReducer>) {
    self.store = store
    super.init()
  }

  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    guard let body = message.body as? [String: Any],
      let actionName = body["name"] as? String else { return }

    switch actionName {
    case "playAll":
      store.send(.player(.playAll))
    case "playSong":
      guard let songId = body["songId"] as? Int else { return }
      store.send(.player(.playSong(songId)))
    case "updateTheme":
      guard
        let theme = body["theme"] as? String,
        let currentTheme = AppReducer.State.Theme(rawValue: theme) else { return }

      store.send(.updateTheme(currentTheme))
    default:
      return
    }
  }
}
