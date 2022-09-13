import ComposableArchitecture
import Turbo

enum AppAction: Equatable {
  case dismissAlert
  case login(LoginState)
  case loginResponse(Result<APIClient.AuthenticationResponse, APIClient.Error>)
  case currentPlaylistResponse(Result<[Song], APIClient.Error>)
  case restoreStates
  case logout
  case getCurrentPlaylist
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
    environment.jsonDataClient.updateCurrentUser(response.user)

    state.currentUser = response.user
    state.serverAddress = response.serverAddress

    return .none

  case .restoreStates:
    state.serverAddress = environment.userDefaultsClient.serverAddress()
    state.apiToken = environment.keychainClient.apiToken()
    state.currentUser = environment.jsonDataClient.currentUser()

    return .none

  case .logout:
    environment.keychainClient.deleteAPIToken()
    environment.cookiesClient.cleanCookies()
    environment.jsonDataClient.deleteCurrentUser()

    state.currentUser = nil

    return .none

  case .getCurrentPlaylist:
    return environment.apiClient.currentPlaylistSongs(state.serverAddress!, state.apiToken!)
      .receive(on: environment.mainQueue)
      .catchToEffect(AppAction.currentPlaylistResponse)

  case let .currentPlaylistResponse(.success(songs)):
    state.player = Player(songs: songs)
    return .none

  case let .loginResponse(.failure(error)), let .currentPlaylistResponse(.failure(error)):
    switch error {
    case .invalidResponse:
      state.alert = .init(title: .init("text.invalidResponse"))
    case .invalidUserCredential:
      state.alert = .init(title: .init("text.invalidUserCredential"))
    case .invalidRequest:
      state.alert = .init(title: .init("text.invalidRequest"))
    }

    return .none
  }
}
