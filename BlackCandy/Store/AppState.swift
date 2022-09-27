import Foundation
import ComposableArchitecture
import Turbo

struct AppState: Equatable {
  var alert: AlertState<AppAction>?
  var serverAddress: URL?
  var apiToken: String?
  var currentUser: User?

  var isLoggedIn: Bool {
    currentUser != nil
  }

  var isAdmin: Bool {
    currentUser?.isAdmin ?? false
  }

  var playerState: PlayerState {
    get {
      var state = _playerState
      state.alert = self.alert

      return state
    }

    set {
      self._playerState = newValue
      self.alert = newValue.alert
    }
  }

  private var _playerState: PlayerState = .init()

  struct PlayerState: Equatable {
    var alert: AlertState<AppAction>?
    var playlist = Playlist()
    var isPlaying = false
    var currentIndex = 0
    var currentTime: Double = 0
    var isPlaylistVisible = false

    var currentSong: Song? {
      get {
        guard playlist.songs.indices.contains(currentIndex) else { return nil }
        return playlist.songs[currentIndex]
      }

      set {
        if let song = newValue, playlist.songs.indices.contains(currentIndex) {
          playlist.songs[currentIndex] = song
        }
      }
    }
  }
}
