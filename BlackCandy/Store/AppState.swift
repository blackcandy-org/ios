import Foundation
import ComposableArchitecture
import Turbo

struct AppState: Equatable {
  var alert: AlertState<AppAction>?
  var serverAddress: URL?
  var apiToken: String?
  var currentUser: User?
  var player: Player?

  var playlist: Playlist? {
    player?.playlist
  }

  var currentSong: Song? {
    playlist?.songs.first
  }

  var isLoggedIn: Bool {
    currentUser != nil
  }

  var isAdmin: Bool {
    currentUser?.isAdmin ?? false
  }

  var hasPlaylistSongs: Bool {
    guard let playlist = playlist else { return false }
    return !playlist.songs.isEmpty
  }
}
