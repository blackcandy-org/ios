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
    case "playAlbum":
      guard let albumId = body["albumId"] as? Int else { return }
      store.send(.player(.playAlbum(albumId)))

    case "playAlbumBeginWith":
      guard
        let albumId = body["albumId"] as? Int,
        let songId = body["songId"] as? Int else { return }

      store.send(.player(.playAlbumBeginWith(albumId, songId)))

    case "playPlaylist":
      guard let playlistId = body["playlistId"] as? Int else { return }
      store.send(.player(.playPlaylist(playlistId)))

    case "playPlaylistBeginWith":
      guard
        let playlistId = body["playlistId"] as? Int,
        let songId = body["songId"] as? Int else { return }

      store.send(.player(.playPlaylistBeginWith(playlistId, songId)))

    case "playNow":
      guard let songId = body["songId"] as? Int else { return }
      store.send(.player(.playNow(songId)))

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
