import Foundation
import ComposableArchitecture
import CoreMedia

struct PlayerReducer: Reducer {
  @Dependency(\.apiClient) var apiClient
  @Dependency(\.playerClient) var playerClient
  @Dependency(\.nowPlayingClient) var nowPlayingClient
  @Dependency(\.cookiesClient) var cookiesClient

  struct State: Equatable {
    var alert: AlertState<AppReducer.AlertAction>?
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

  enum Action: Equatable {
    case play
    case pause
    case stop
    case next
    case previous
    case playOn(Int)
    case getCurrentTime
    case updateCurrentTime(Double)
    case toggleFavorite
    case toggleFavoriteResponse(TaskResult<APIClient.NoContentResponse>)
    case togglePlaylistVisible
    case seekToRatio(Double)
    case seekToPosition(TimeInterval)
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
    case playSong(Int)
    case playSongResponse(TaskResult<Song>)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .play:
        if playerClient.hasCurrentItem() {
          playerClient.play()
          return .none
        } else {
          return self.playOn(state: &state, index: state.currentIndex)
        }

      case .pause:
        playerClient.pause()
        return .none

      case .stop:
        state.currentSong = nil
        playerClient.stop()

        return .none

      case .next:
        return self.playOn(state: &state, index: state.currentIndex + 1)

      case .previous:
        return self.playOn(state: &state, index: state.currentIndex - 1)

      case let .playOn(index):
        return self.playOn(state: &state, index: index)

      case .getCurrentTime:
        return .run { send in
          for await currentTime in playerClient.getCurrentTime() {
            await send(.updateCurrentTime(currentTime))
          }
        }

      case let .updateCurrentTime(currentTime):
        state.currentTime = currentTime

        return .none

      case .toggleFavorite:
        guard let currentSong = state.currentSong else { return .none }

        state.currentSong?.isFavorited = !currentSong.isFavorited

        return .run { send in
          await send(
            .toggleFavoriteResponse(
              TaskResult { try await apiClient.toggleFavorite(currentSong) }
            )
          )
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

      case let .seekToRatio(ratio):
        guard let currentSong = state.currentSong else { return .none }
        let position = currentSong.duration * ratio

        return .send(.seekToPosition(position))

      case let .seekToPosition(position):
        let time = CMTime(seconds: position, preferredTimescale: 1)
        playerClient.seek(time)

        return .none

      case .getStatus:
        return .run { send in
          for await status in playerClient.getStatus() {
            await send(.handleStatusChange(status))
          }
        }

      case let .handleStatusChange(status):
        let playbackRate = playerClient.getPlaybackRate()
        nowPlayingClient.updatePlaybackInfo(Float(state.currentTime), playbackRate)

        state.status = status

        guard status == .end else { return .none }

        if state.mode == .single {
          playerClient.replay()
          return .none
        } else {
          return .send(.next)
        }

      case .nextMode:
        state.mode = state.mode.next()
        state.playlist.isShuffled = (state.mode == .shuffle)

        return .none

      case let .deleteSongs(indexSet):
        let songs = indexSet.map { state.playlist.songs[$0] }

        state.playlist.remove(songs: songs)

        if let currentSong = state.currentSong, songs.contains(currentSong) {
          state.currentSong = nil
          playerClient.stop()
        }

        return .run { send in
          await send(
            .deleteSongsResponse(
              TaskResult { try await apiClient.deleteCurrentPlaylistSongs(songs) }
            )
          )
        }

      case let .moveSongs(fromOffsets, toOffset):
        guard let fromIndex = fromOffsets.first else { return .none }
        let movedSong = state.playlist.orderedSongs[fromIndex]

        state.playlist.orderedSongs.move(fromOffsets: fromOffsets, toOffset: toOffset)

        guard let toIndex = state.playlist.orderedSongs.firstIndex(of: movedSong) else { return .none }

        return .run { send in
          await send(
            .moveSongsResponse(
              TaskResult { try await apiClient.moveCurrentPlaylistSongs(fromIndex + 1, toIndex + 1) }
            )
          )
        }

      case .deleteSongsResponse(.success), .moveSongsResponse(.success):
        return .none

      case .getCurrentPlaylist:
        return .run { send in
          await send(
            .currentPlaylistResponse(
              TaskResult { try await apiClient.getCurrentPlaylistSongs() }
            )
          )
        }

      case let .currentPlaylistResponse(.success(songs)):
        state.playlist.update(songs: songs)
        state.currentSong = songs.first

        return .none

      case .playAll:
        return .run { send in
          await send(
            .playAllResponse(
              TaskResult { try await apiClient.getCurrentPlaylistSongs() }
            )
          )
        }

      case let .playAllResponse(.success(songs)):
        state.playlist.update(songs: songs)
        state.currentSong = songs.first

        return self.playOn(state: &state, index: 0)

      case let .playSong(songId):
        if let songIndex = state.playlist.index(by: songId) {
          return self.playOn(state: &state, index: songIndex)
        } else {
          return .run { [currentSong = state.currentSong] send in
            await send(
              .playSongResponse(
                TaskResult { try await apiClient.addCurrentPlaylistSong(songId, currentSong) }
              )
            )
          }
        }

      case let .playSongResponse(.success(song)):
        let insertIndex = min(state.currentIndex + 1, state.playlist.songs.endIndex)
        state.playlist.insert(song, at: insertIndex)

        return self.playOn(state: &state, index: insertIndex)

      case let .deleteSongsResponse(.failure(error)),
        let .moveSongsResponse(.failure(error)),
        let .currentPlaylistResponse(.failure(error)),
        let .playAllResponse(.failure(error)),
        let .playSongResponse(.failure(error)):
        guard let error = error as? APIClient.APIError else { return .none }
        state.alert = .init(title: .init(error.localizedString))

        return .none
      }
    }
  }

  func playOn(state: inout State, index: Int) -> Effect<Action> {
    let songsCount = state.playlist.songs.count

    if index >= songsCount {
      state.currentSong = state.playlist.songs.first
    } else if index < 0 {
      state.currentSong = state.playlist.songs.last
    } else {
      state.currentSong = state.playlist.songs[index]
    }

    guard let currentSong = state.currentSong else { return .none }

    playerClient.playOn(currentSong.url)

    return .run { _ in
      await withTaskGroup(of: Void.self) { taskGroup in
        taskGroup.addTask {
          await nowPlayingClient.updateInfo(currentSong)
        }

        taskGroup.addTask {
          await cookiesClient.createCookie("current_song_id", String(currentSong.id))
        }
      }
    }
  }
}

extension PlayerReducer.State {
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
