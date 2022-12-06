import Foundation
import ComposableArchitecture
import Turbo
import SwiftUI

struct AppState: Equatable {
  var alert: AlertState<AppAction>?
  var serverAddress: URL?
  var apiToken: String?
  var currentUser: User?
  var currentTheme = Theme.auto

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
    var currentSong: Song?
    var currentTime: Double = 0
    var isPlaylistVisible = false
    var status = PlayerClient.Status.pause
    var mode = Mode.repead

    var isPlaying: Bool {
      status == .playing || status == .loading
    }

    var currentIndex: Int {
      guard let currentSong = currentSong else { return 0 }
      return playlist.songs.firstIndex(of: currentSong) ?? 0
    }

    var hasCurrentSong: Bool {
      currentSong != nil
    }
  }

  enum Theme: String {
    case auto
    case light
    case dark

    var colorScheme: ColorScheme? {
      switch self {
      case .dark:
        return ColorScheme.dark
      case .light:
        return ColorScheme.light
      case .auto:
        return nil
      }
    }
  }
}

extension AppState.PlayerState {
  enum Mode: CaseIterable {
    case repead
    case single
    case shuffle

    var symbol: String {
      switch self {
      case .repead:
        return "repeat"
      case .single:
        return "repeat.1"
      case .shuffle:
        return "shuffle"
      }
    }

    func next() -> Self {
      Self.allCases[(Self.allCases.firstIndex(of: self)! + 1) % Self.allCases.count]
    }
  }
}
