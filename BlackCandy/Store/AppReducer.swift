import Foundation
import SwiftUI
import ComposableArchitecture

struct AppReducer: ReducerProtocol {
  @Dependency(\.userDefaultsClient) var userDefaultsClient
  @Dependency(\.cookiesClient) var cookiesClient
  @Dependency(\.keychainClient) var keychainClient
  @Dependency(\.jsonDataClient) var jsonDataClient
  @Dependency(\.windowClient) var windowClient

  struct State: Equatable {
    var alert: AlertState<Action>?
    var serverAddress: URL?
    var currentUser: User?
    var currentTheme = Theme.auto

    var isLoggedIn: Bool {
      currentUser != nil
    }

    var isAdmin: Bool {
      currentUser?.isAdmin ?? false
    }

    var player: PlayerReducer.State {
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

    var login: LoginReducer.State {
      get {
        var state = _loginState
        state.alert = self.alert
        state.currentUser = self.currentUser
        state.serverAddress = self.serverAddress

        return state
      }

      set {
        self._loginState = newValue

        self.alert = newValue.alert
        self.currentUser = newValue.currentUser
        self.serverAddress = newValue.serverAddress
      }
    }

    private var _loginState: LoginReducer.State = .init()
    private var _playerState: PlayerReducer.State = .init()
  }

  enum Action: Equatable {
    case dismissAlert
    case restoreStates
    case logout
    case updateTheme(State.Theme)
    case player(PlayerReducer.Action)
    case login(LoginReducer.Action)
  }

  var body: some ReducerProtocolOf<Self> {
    Reduce { state, action in
      switch action {
      case .restoreStates:
        state.serverAddress = userDefaultsClient.serverAddress()
        state.currentUser = jsonDataClient.currentUser()

        return .none

      case .logout:
        keychainClient.deleteAPIToken()
        jsonDataClient.deleteCurrentUser()
        windowClient.switchToLoginView()

        state.currentUser = nil

        return .run { _ in
          await cookiesClient.cleanCookies()
        }

      case let .updateTheme(theme):
        state.currentTheme = theme
        return .none

      case .dismissAlert:
        state.alert = nil
        return .none

      case .player:
        return .none

      case .login:
        return .none
      }
    }

    Scope(state: \.player, action: /Action.player) {
      PlayerReducer()
    }

    Scope(state: \.login, action: /Action.login) {
      LoginReducer()
    }
  }
}

extension AppReducer.State {
  enum Theme: String {
    case auto
    case light
    case dark

    var interfaceStyle: UIUserInterfaceStyle {
      switch self {
      case .dark:
        return .dark
      case .light:
        return .light
      case .auto:
        return .unspecified
      }
    }

    var colorScheme: ColorScheme? {
      switch self {
      case .dark:
        return .dark
      case .light:
        return .light
      case .auto:
        return nil
      }
    }
  }
}
