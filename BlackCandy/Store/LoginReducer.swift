import Foundation
import ComposableArchitecture

struct LoginReducer: ReducerProtocol {
  @Dependency(\.apiClient) var apiClient
  @Dependency(\.userDefaultsClient) var userDefaultsClient
  @Dependency(\.cookiesClient) var cookiesClient
  @Dependency(\.keychainClient) var keychainClient
  @Dependency(\.jsonDataClient) var jsonDataClient
  @Dependency(\.windowClient) var windowClient

  struct State: Equatable {
    var alert: AlertState<AppReducer.Action>?
    var serverAddress: URL?
    var currentUser: User?

    @BindingState var isAuthenticationViewVisible = false
  }

  enum Action: Equatable, BindableAction {
    case getSystemInfo(ServerAddressState)
    case systemInfoResponse(TaskResult<SystemInfo>)
    case login(LoginState)
    case loginResponse(TaskResult<APIClient.AuthenticationResponse>)
    case binding(BindingAction<State>)
  }

  var body: some ReducerProtocolOf<Self> {
    BindingReducer()

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
        state.isAuthenticationViewVisible = true

        return .none

      case let .login(loginState):
        return .task {
          await .loginResponse(TaskResult { try await apiClient.authentication(loginState) })
        }

      case .binding(\.$isAuthenticationViewVisible):
        return .none

      case let .loginResponse(.success(response)):
        cookiesClient.updateCookies(response.cookies, nil)
        keychainClient.updateAPIToken(response.token)
        jsonDataClient.updateCurrentUser(response.user, nil)

        state.currentUser = response.user

        windowClient.switchToMainView()

        return .none

      case let .loginResponse(.failure(error)),
        let .systemInfoResponse(.failure(error)):
        guard let error = error as? APIClient.APIError else { return .none }
        state.alert = .init(title: .init(error.localizedString))

        return .none

      case .binding:
        return .none
      }
    }
  }
}
