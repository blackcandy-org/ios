import ComposableArchitecture
import Turbo

enum AppAction: Equatable {
  case dismissAlert
  case login(LoginState)
  case loginResponse(Result<APIClient.AuthenticationResponse, APIClient.Error>)
  case restoreStates
  case updateLoginSheetVisibility(Bool)
  case updateCurrentSession(Session)
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
  switch action {
  case let .login(loginState):
    if loginState.hasValidServerAddress {
      return environment.apiClient.authentication(loginState)
        .receive(on: environment.mainQueue)
        .catchToEffect(AppAction.loginResponse)
    } else {
      state.alert = .init(title: .init("text.invalidServerAddress"))
      return .none
    }

  case .dismissAlert:
    state.alert = nil
    return .none

  case let .loginResponse(.success(response)):
    environment.userDefaultsClient.updateServerAddress(response.serverAddress)
    environment.cookiesClient.updateCookies(response.cookies)
    environment.keychainClient.updateAPIToken(response.token)

    state.serverAddress = response.serverAddress
    state.isLoginSheetVisible = false
    state.currentSession?.reload()

    return .none

  case .loginResponse(.failure(.invalidUserCredential)):
    state.alert = .init(title: .init("text.invalidUserCredential"))
    return .none

  case .loginResponse(.failure(.invalidRequest)):
    state.alert = .init(title: .init("text.invalidRequest"))
    return .none

  case .loginResponse(.failure(.invalidResponse)):
    state.alert = .init(title: .init("text.invalidResponse"))
    return .none

  case .restoreStates:
    state.serverAddress = environment.userDefaultsClient.serverAddress()
    state.apiToken = environment.keychainClient.apiToken()

    return .none

  case let .updateLoginSheetVisibility(isVisible):
    state.isLoginSheetVisible = isVisible
    return .none

  case let .updateCurrentSession(session):
    state.currentSession = session
    return .none
  }
}
