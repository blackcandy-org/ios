import Foundation
import WebKit
import ComposableArchitecture

class TurboScriptMessageHandler: NSObject, WKScriptMessageHandler {
  @Dependency(\.flashMessageClient) var flashMessageClient

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
      guard let resourceType = body["resourceType"] as? String,
        let resourceId = body["resourceId"] as? Int else { return }

      store.send(.player(.playAll(resourceType, resourceId)))
    case "playSong":
      guard let songId = body["songId"] as? Int else { return }
      store.send(.player(.playSong(songId)))
    case "playNext":
      guard let songId = body["songId"] as? Int else { return }
      store.send(.player(.playNext(songId)))
    case "playLast":
      guard let songId = body["songId"] as? Int else { return }
      store.send(.player(.playLast(songId)))
    case "showFlashMessage":
      guard let message = body["message"] as? String else { return }
      flashMessageClient.showMessage(message)
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
