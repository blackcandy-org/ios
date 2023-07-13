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
  @Dependency(\.windowClient) var windowClient

  struct State: Equatable {
    var alert: AlertState<Action>?
    var serverAddress: URL?
    var currentUser: User?
    var currentTheme = Theme.auto
    var isLoginViewVisible = false

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
    case getSystemInfo(ServerAddressState)
    case systemInfoResponse(TaskResult<SystemInfo>)
    case login(LoginState)
    case loginResponse(TaskResult<APIClient.AuthenticationResponse>)
    case restoreStates
    case logout
    case updateTheme(State.Theme)
    case updateLoginViewVisible(Bool)
    case player(PlayerReducer.Action)
  }

  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case let .getSystemInfo(serverAddressState):
        if serverAddressState.isUrlValid {
          return .task {
            await .systemInfoResponse(TaskResult { try await apiClient.getSystemInfo(serverAddressState) })
          }
        } else {
          state.alert = .init(title: .init("text.invalidServerAddress"))
          return .none
        }

      case let .systemInfoResponse(.success(systemInfo)):
        guard let serverAddress = systemInfo.serverAddress else {
          state.alert = .init(title: .init("text.invalidServerAddress"))
          return .none
        }

        guard systemInfo.isSupported else {
          state.alert = .init(title: .init("text.unsupportedServer"))
          return .none
        }

        userDefaultsClient.updateServerAddress(serverAddress)

        state.serverAddress = serverAddress
        state.isLoginViewVisible = true

        return .none

      case let .login(loginState):
        return .task {
          await .loginResponse(TaskResult { try await apiClient.authentication(loginState) })
        }

      case .dismissAlert:
        state.alert = nil
        return .none

      case let .loginResponse(.success(response)):
        cookiesClient.updateCookies(response.cookies, nil)
        keychainClient.updateAPIToken(response.token)
        jsonDataClient.updateCurrentUser(response.user, nil)

        state.currentUser = response.user

        windowClient.changeRootViewController(MainViewController(store: AppStore.shared))

        return .none

      case .restoreStates:
        state.serverAddress = userDefaultsClient.serverAddress()
        state.currentUser = jsonDataClient.currentUser()

        return .none

      case .logout:
        keychainClient.deleteAPIToken()
        cookiesClient.cleanCookies(nil)
        jsonDataClient.deleteCurrentUser()

        windowClient.changeRootViewController(UIHostingController(rootView: LoginView(store: AppStore.shared)))

        state.currentUser = nil

        return .none

      case let .loginResponse(.failure(error)),
        let .systemInfoResponse(.failure(error)):
        guard let error = error as? APIClient.APIError else { return .none }
        state.alert = .init(title: .init(error.localizedString))

        return .none

      case let .updateTheme(theme):
        state.currentTheme = theme
        return .none

      case let .updateLoginViewVisible(isVisible):
        state.isLoginViewVisible = isVisible
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
