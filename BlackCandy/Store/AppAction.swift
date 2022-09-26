import ComposableArchitecture
import Turbo
import Alamofire

enum AppAction: Equatable {
  case dismissAlert
  case login(LoginState)
  case loginResponse(TaskResult<APIClient.AuthenticationResponse>)
  case currentPlaylistResponse(TaskResult<[Song]>)
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
    case updateCurrentTime(Double)
    case toggleFavorite
    case toggleFavoriteResponse(TaskResult<APIClient.NoContentResponse>)
  }
}

let playerStateReducer = Reducer<AppState.PlayerState, AppAction.PlayerAction, AppEnvironment.PlayerEnvironment> { state, action, environment in
  switch action {
  case .play:
    return .task { [currentIndex = state.currentIndex] in
      .playOn(currentIndex)
    }

  case .pause:
    state.isPlaying = false
    environment.playerClient.pause()

    return .none

  case .next:
    return .task { [currentIndex = state.currentIndex] in
      .playOn(currentIndex + 1)
    }

  case .previous:
    return .task { [currentIndex = state.currentIndex] in
      .playOn(currentIndex - 1)
    }

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

    return .run { send in
      for await currentTime in environment.playerClient.getCurrentTime() {
        await send(.updateCurrentTime(currentTime))
      }
    }

  case let .updateCurrentTime(currentTime):
    state.currentTime = currentTime

    return .none

  case .toggleFavorite:
    guard let currentSong = state.currentSong else { return .none }

    state.currentSong?.isFavorited = !currentSong.isFavorited

    return .task {
      await .toggleFavoriteResponse(TaskResult { try await environment.apiClient.toggleFavorite(currentSong) })
    }

  case .toggleFavoriteResponse(.success):
    return .none

  // Toogle favorite state back if toggle favorite failed
  case let .toggleFavoriteResponse(.failure(error)):
    state.currentSong?.isFavorited.toggle()

    guard let error = error as? APIClient.APIError else { return .none }
    state.alert = .init(title: .init(error.localizedString))

    return .none
  }
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment>.combine(
  playerStateReducer.pullback(
    state: \AppState.playerState,
    action: /AppAction.player,
    environment: {
      AppEnvironment.PlayerEnvironment(
        playerClient: $0.playerClient,
        apiClient: $0.apiClient
      )
    }
  ),

  Reducer { state, action, environment in
    switch action {
    case let .login(loginState):
      if loginState.hasValidServerAddress {
        return .task {
          await .loginResponse(TaskResult { try await environment.apiClient.authentication(loginState) })
        }
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
      environment.apiClient.updateToken(state.apiToken)
      environment.apiClient.updateServerAddress(state.serverAddress)

      return .none

    case .logout:
      environment.keychainClient.deleteAPIToken()
      environment.cookiesClient.cleanCookies()
      environment.jsonDataClient.deleteCurrentUser()

      state.currentUser = nil

      return .none

    case .getCurrentPlaylist:
      return .task {
        await .currentPlaylistResponse(TaskResult { try await environment.apiClient.currentPlaylistSongs() })
      }

    case let .currentPlaylistResponse(.success(songs)):
      state.playerState.playlist.songs = songs

      return .none

    case let .loginResponse(.failure(error)), let .currentPlaylistResponse(.failure(error)):
      guard let error = error as? APIClient.APIError else { return .none }
      state.alert = .init(title: .init(error.localizedString))

      return .none

    case .player:
      return .none
    }
  }
)
