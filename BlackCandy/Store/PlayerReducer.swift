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
    case updateCurrentTime(Double)
    case toggleFavorite
    case toggleFavoriteResponse(TaskResult<Int>)
    case togglePlaylistVisible
    case seekToRatio(Double)
    case seekToPosition(TimeInterval)
    case getStatus
    case getCurrentTime
    case getLivingStates
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

      case let .updateCurrentTime(currentTime):
        state.currentTime = currentTime

        return .none

      case .toggleFavorite:
        guard let currentSong = state.currentSong else { return .none }

        return .run { send in
          await send(
            .toggleFavoriteResponse(
              TaskResult { try await apiClient.toggleFavorite(currentSong) }
            )
          )
        }

      case let .toggleFavoriteResponse(.success(songId)):
        guard var song = state.playlist.find(bySongId: songId) else { return .none }
        song.isFavorited.toggle()

        state.playlist.update(song: song)

        if state.currentSong?.id == songId {
          state.currentSong = song
        }

        return .none

      case let .toggleFavoriteResponse(.failure(error)):
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

      case .getCurrentTime:
        return .run { send in
          for await currentTime in playerClient.getCurrentTime() {
            await send(.updateCurrentTime(currentTime))
          }
        }

      case .getStatus:
        return .run { send in
          for await status in playerClient.getStatus() {
            await send(.handleStatusChange(status))
          }
        }

      case .getLivingStates:
        return .run { send in
          await withTaskGroup(of: Void.self) { taskGroup in
            taskGroup.addTask {
              await send(.getStatus)
            }

            taskGroup.addTask {
              await send(.getCurrentTime)
            }
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
        let currentIndex = state.currentIndex

        state.playlist.remove(songs: songs)

        if let currentSong = state.currentSong, songs.contains(currentSong) {
          playerClient.stop()
          state.currentSong = state.playlist.find(byIndex: currentIndex)
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
        var destinationIndex = toOffset

        if fromIndex < toOffset {
          destinationIndex -= 1
        }

        let movingSong = state.playlist.orderedSongs[fromIndex]
        let destinationSong = state.playlist.orderedSongs[destinationIndex]

        state.playlist.orderedSongs.move(fromOffsets: fromOffsets, toOffset: toOffset)

        return .run { send in
          await send(
            .moveSongsResponse(
              TaskResult { try await apiClient.moveCurrentPlaylistSongs(movingSong.id, destinationSong.id) }
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

        guard let currentSong = state.currentSong else {
          state.currentSong = songs.first
          return .none
        }

        if !state.isPlaying && (state.playlist.index(of: currentSong) == nil) {
          state.currentSong = songs.first
          playerClient.stop()
        }

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
    state.currentSong = state.playlist.find(byIndex: index)
    guard let currentSong = state.currentSong else { return .none }

    playerClient.playOn(currentSong.url)

    return .run { _ in
      await nowPlayingClient.updateInfo(currentSong)
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
