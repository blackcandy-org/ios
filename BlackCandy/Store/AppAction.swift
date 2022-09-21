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
  case player(PlayerAction)

  enum PlayerAction: Equatable {
    case play
    case pause
    case next
    case previous
    case playOn(Int)
    case updateCurrentTime(Result<Double, Never>)
  }
}

let playerStateReducer = Reducer<AppState.PlayerState, AppAction.PlayerAction, AppEnvironment.PlayerEnvironment> { state, action, environment in
  switch action {
  case .play:
    return .init(value: .playOn(state.currentIndex))

  case .pause:
    state.isPlaying = false
    environment.playerClient.pause()

    return .none

  case .next:
    return .init(value: .playOn(state.currentIndex + 1))

  case .previous:
    return .init(value: .playOn(state.currentIndex - 1))

  case let .playOn(index):
    if state.currentIndex == index && environment.playerClient.hasCurrentItem() {
      state.isPlaying = true
      environment.playerClient.play()

      return .none
    }

    let songsCount = state.playlist.songs.count

    if index >= songsCount {
      state.currentIndex = 0
    } else if index < 0 {
      state.currentIndex = songsCount - 1
    } else {
      state.currentIndex = index
    }

    guard let currentSong = state.currentSong else { return .none }

    state.isPlaying = true
    environment.playerClient.playOn(currentSong)

    return environment.playerClient.getCurrentTime()
      .catchToEffect(AppAction.PlayerAction.updateCurrentTime)

  case let .updateCurrentTime(.success(currentTime)):
    state.currentTime = currentTime

    return .none
  }
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
  playerStateReducer.pullback(
    state: \AppState.playerState,
    action: /AppAction.player,
    environment: {
      AppEnvironment.PlayerEnvironment(
        mainQueue: $0.mainQueue,
        playerClient: $0.playerClient
      )
    }
  ),

  Reducer { state, action, environment in
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
      environment.playerClient.updateAPIToken(response.token)

      state.currentUser = response.user
      state.serverAddress = response.serverAddress
      state.apiToken = response.token

      return .none

    case .restoreStates:
      state.serverAddress = environment.userDefaultsClient.serverAddress()
      state.currentUser = environment.jsonDataClient.currentUser()
      state.apiToken = environment.keychainClient.apiToken()

      environment.playerClient.updateAPIToken(state.apiToken)

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
      state.playerState.playlist.songs = songs

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

    case .player:
      return .none
    }
  }
)
