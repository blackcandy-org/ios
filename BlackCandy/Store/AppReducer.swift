import Foundation
import SwiftUI
import ComposableArchitecture

struct AppReducer: ReducerProtocol {
  @Dependency(\.apiClient) var apiClient
  @Dependency(\.userDefaultsClient) var userDefaultsClient
  @Dependency(\.cookiesClient) var cookiesClient
  @Dependency(\.keychainClient) var keychainClient
  @Dependency(\.jsonDataClient) var jsonDataClient
  @Dependency(\.playerClient) var playerClient

  struct State: Equatable {
    var alert: AlertState<Action>?
    var serverAddress: URL?
    var apiToken: String?
    var currentUser: User?
    var currentTheme = Theme.auto
    var isAccountSheetVisible = false

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

    private var _playerState: PlayerReducer.State = .init()
  }

  enum Action: Equatable {
    case dismissAlert
    case login(LoginState)
    case loginResponse(TaskResult<APIClient.AuthenticationResponse>)
    case restoreStates
    case logout
    case updateTheme(State.Theme)
    case updateAccountSheetVisible(Bool)
    case player(PlayerReducer.Action)
  }

  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case let .login(loginState):
        if loginState.hasValidServerAddress {
          return .task {
            await .loginResponse(TaskResult { try await apiClient.authentication(loginState) })
          }
        } else {
          state.alert = .init(title: .init("text.invalidServerAddress"))
          return .none
        }

      case .dismissAlert:
        state.alert = nil
        return .none

      case let .loginResponse(.success(response)):
        userDefaultsClient.updateServerAddress(response.serverAddress)
        cookiesClient.updateCookies(response.cookies)
        cookiesClient.updateServerAddress(response.serverAddress)
        keychainClient.updateAPIToken(response.token)
        jsonDataClient.updateCurrentUser(response.user)
        playerClient.updateAPIToken(response.token)
        apiClient.updateToken(response.token)
        apiClient.updateServerAddress(response.serverAddress)

        state.currentUser = response.user
        state.serverAddress = response.serverAddress
        state.apiToken = response.token

        return .none

      case .restoreStates:
        state.serverAddress = userDefaultsClient.serverAddress()
        state.currentUser = jsonDataClient.currentUser()
        state.apiToken = keychainClient.apiToken()

        playerClient.updateAPIToken(state.apiToken)
        apiClient.updateToken(state.apiToken)
        apiClient.updateServerAddress(state.serverAddress)
        cookiesClient.updateServerAddress(state.serverAddress)

        return .none

      case .logout:
        keychainClient.deleteAPIToken()
        cookiesClient.cleanCookies()
        jsonDataClient.deleteCurrentUser()

        state.currentUser = nil

        return .none

      case let .loginResponse(.failure(error)):
        guard let error = error as? APIClient.APIError else { return .none }
        state.alert = .init(title: .init(error.localizedString))

        return .none

      case let .updateTheme(theme):
        state.currentTheme = theme
        return .none

      case let .updateAccountSheetVisible(isVisible):
        state.isAccountSheetVisible = isVisible
        return .none

      case .player:
        return .none
      }
    }

    Scope(state: \.player, action: /Action.player) {
      PlayerReducer()
    }
  }
}

extension AppReducer.State {
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
