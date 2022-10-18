import ComposableArchitecture
import Turbo
import Alamofire
import CoreMedia

enum AppAction: Equatable {
  case dismissAlert
  case login(LoginState)
  case loginResponse(TaskResult<APIClient.AuthenticationResponse>)
  case restoreStates
  case logout
  case player(PlayerAction)

  enum PlayerAction: Equatable {
    case play
    case pause
    case next
    case previous
    case playOn(Int)
    case getCurrentTime
    case updateCurrentTime(Double)
    case toggleFavorite
    case toggleFavoriteResponse(TaskResult<APIClient.NoContentResponse>)
    case togglePlaylistVisible
    case seek(Double)
    case getStatus
    case handleStatusChange(PlayerClient.Status)
    case nextMode
    case deleteSongs(IndexSet)
    case deleteSongsResponse(TaskResult<APIClient.NoContentResponse>)
    case moveSongs(IndexSet, Int)
    case moveSongsResponse(TaskResult<APIClient.NoContentResponse>)
    case getCurrentPlaylist
    case currentPlaylistResponse(TaskResult<[Song]>)
    case playAll
    case playAllResponse(TaskResult<[Song]>)
  }
}

let playerStateReducer = Reducer<AppState.PlayerState, AppAction.PlayerAction, AppEnvironment.PlayerEnvironment> { state, action, environment in
  switch action {
  case .play:
    if environment.playerClient.hasCurrentItem() {
      environment.playerClient.play()
      return .none
    } else {
      return .task { [currentIndex = state.currentIndex] in
        .playOn(currentIndex)
      }
    }

  case .pause:
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
    let songsCount = state.playlist.songs.count

    if index >= songsCount {
      state.currentSong = state.playlist.songs.first
    } else if index < 0 {
      state.currentSong = state.playlist.songs[songsCount - 1]
    } else {
      state.currentSong = state.playlist.songs[index]
    }

    guard let currentSong = state.currentSong else { return .none }

    environment.playerClient.playOn(currentSong)

    return .none

  case .getCurrentTime:
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

  case .togglePlaylistVisible:
    state.isPlaylistVisible.toggle()

    return .none

  case let .seek(ratio):
    guard let currentSong = state.currentSong else { return .none }
    let time = CMTime(seconds: currentSong.duration * ratio, preferredTimescale: 1)

    environment.playerClient.seek(time)

    return .none

  case .getStatus:
    return .run { send in
      for await status in environment.playerClient.getStatus() {
        await send(.handleStatusChange(status))
      }
    }

  case let .handleStatusChange(status):
    state.status = status

    guard status == .end else { return .none }

    if state.mode == .single {
      environment.playerClient.replay()
      return .none
    } else {
      return .task { .next }
    }

  case .nextMode:
    state.mode = state.mode.next()
    state.playlist.isShuffled = (state.mode == .shuffle)

    return .none

  case let .deleteSongs(indexSet):
    let songs = indexSet.map { state.playlist.songs[$0] }

    state.playlist.remove(songs: songs)

    return .task {
      await .deleteSongsResponse(TaskResult { try await environment.apiClient.deleteCurrentPlaylistSongs(songs) })
    }

  case let .moveSongs(fromOffsets, toOffset):
    guard let fromIndex = fromOffsets.first else { return .none }
    let movedSong = state.playlist.orderedSongs[fromIndex]

    state.playlist.orderedSongs.move(fromOffsets: fromOffsets, toOffset: toOffset)

    guard let toIndex = state.playlist.orderedSongs.firstIndex(of: movedSong) else { return .none }

    return .task {
      await .moveSongsResponse(TaskResult { try await environment.apiClient.moveCurrentPlaylistSongs(fromIndex + 1, toIndex + 1) })
    }

  case .deleteSongsResponse(.success), .moveSongsResponse(.success):
    return .none

  case .getCurrentPlaylist:
    return .task {
      await .currentPlaylistResponse(TaskResult { try await environment.apiClient.currentPlaylistSongs() })
    }

  case let .currentPlaylistResponse(.success(songs)):
    state.playlist.update(songs: songs)
    state.currentSong = songs.first

    return .none

  case .playAll:
    return .task {
      await .playAllResponse(TaskResult { try await environment.apiClient.currentPlaylistSongs() })
    }

  case let .playAllResponse(.success(songs)):
    state.playlist.update(songs: songs)
    state.currentSong = songs.first

    return .task {
      .playOn(0)
    }

  case let .deleteSongsResponse(.failure(error)),
    let .moveSongsResponse(.failure(error)),
    let .currentPlaylistResponse(.failure(error)),
    let .playAllResponse(.failure(error)):
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
      environment.apiClient.updateToken(response.token)
      environment.apiClient.updateServerAddress(response.serverAddress)

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

    case let .loginResponse(.failure(error)):
      guard let error = error as? APIClient.APIError else { return .none }
      state.alert = .init(title: .init(error.localizedString))

      return .none

    case .player:
      return .none
    }
  }
)
