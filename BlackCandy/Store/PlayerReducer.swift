import Foundation
import ComposableArchitecture
import CoreMedia

struct PlayerReducer: Reducer {
  @Dependency(\.apiClient) var apiClient
  @Dependency(\.playerClient) var playerClient
  @Dependency(\.nowPlayingClient) var nowPlayingClient
  @Dependency(\.cookiesClient) var cookiesClient
  @Dependency(\.flashMessageClient) var flashMessageClient

  struct State: Equatable {
    var alert: AlertState<AppReducer.AlertAction>?
    var playlist = Playlist()
    var currentSong: Song?
    var currentTime: Double = 0
    var isPlaylistVisible = false
    var status = PlayerClient.Status.pause
    var mode = Mode.noRepeat

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

    mutating func insertSongNextToCurrent(song: Song) -> Int {
      let insertIndex = min(currentIndex + 1, playlist.songs.endIndex)
      playlist.insert(song, at: insertIndex)

      return insertIndex
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
    case playAlbum(Int)
    case playAlbumBeginWith(Int, Int)
    case playPlaylist(Int)
    case playPlaylistBeginWith(Int, Int)
    case playSongsResponse(TaskResult<[Song]>)
    case playSongsBeginWithResponse(TaskResult<[Song]>, Int)
    case playNow(Int)
    case playNext(Int)
    case playLast(Int)
    case playNowResponse(TaskResult<Song>)
    case playNextResponse(TaskResult<Song>)
    case playLastResponse(TaskResult<Song>)
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
              TaskResult {
                if currentSong.isFavorited {
                  return try await apiClient.deleteSongInFavorite(currentSong)
                } else {
                  return try await apiClient.addSongToFavorite(currentSong)
                }
              }
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

        switch state.mode {
        case .noRepeat:
          if state.currentIndex == state.playlist.songs.count - 1 {
            playerClient.stop()
            state.currentSong = state.playlist.songs.first

            return .none
          } else {
            return .send(.next)
          }
        case .single:
          playerClient.replay()
          return .none
        default:
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
          await withTaskGroup(of: Void.self) { taskGroup in
            for song in songs {
              taskGroup.addTask {
                await send(
                  .deleteSongsResponse(
                    TaskResult { try await apiClient.deleteSongInCurrentPlaylist(song) }
                  )
                )
              }
            }
          }
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
              TaskResult { try await apiClient.moveSongInCurrentPlaylist(movingSong.id, destinationSong.id) }
            )
          )
        }

      case .deleteSongsResponse(.success), .moveSongsResponse(.success):
        return .none

      case .getCurrentPlaylist:
        return .run { send in
          await send(
            .currentPlaylistResponse(
              TaskResult { try await apiClient.getSongsFromCurrentPlaylist() }
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

      case let .playAlbum(albumId):
        return .run { send in
          await send(
            .playSongsResponse(
              TaskResult {
                try await apiClient.replaceCurrentPlaylistWithAlbumSongs(albumId)
              }
            )
          )
        }

      case let .playAlbumBeginWith(albumId, songId):
        return .run { send in
          await send(
            .playSongsBeginWithResponse(
              TaskResult { try await apiClient.replaceCurrentPlaylistWithAlbumSongs(albumId) },
              songId
            )
          )
        }

      case let .playPlaylist(playlistId):
        return .run { send in
          await send(
            .playSongsResponse(
              TaskResult {
                try await apiClient.replaceCurrentPlaylistWithPlaylistSongs(playlistId)
              }
            )
          )
        }

      case let .playPlaylistBeginWith(playlistId, songId):
        return .run { send in
          await send(
            .playSongsBeginWithResponse(
              TaskResult { try await apiClient.replaceCurrentPlaylistWithPlaylistSongs(playlistId) },
              songId
            )
          )
        }

      case let .playSongsResponse(.success(songs)):
        state.playlist.update(songs: songs)
        state.currentSong = songs.first

        return self.playOn(state: &state, index: 0)

      case let .playSongsBeginWithResponse(.success(songs), songId):
        state.playlist.update(songs: songs)

        if let songIndex = state.playlist.index(by: songId) {
          state.currentSong = state.playlist.find(byIndex: songIndex)
          return self.playOn(state: &state, index: songIndex)
        } else {
          state.currentSong = songs.first
          return self.playOn(state: &state, index: 0)
        }

      case let .playNow(songId):
        if let songIndex = state.playlist.index(by: songId) {
          return self.playOn(state: &state, index: songIndex)
        } else {
          return .run { [currentSong = state.currentSong] send in
            await send(
              .playNowResponse(
                TaskResult { try await apiClient.addSongToCurrentPlaylist(songId, currentSong, nil) }
              )
            )
          }
        }

      case let .playNext(songId):
        return .run { [currentSong = state.currentSong] send in
          await send(
            .playNextResponse(
              TaskResult { try await apiClient.addSongToCurrentPlaylist(songId, currentSong, nil) }
            )
          )
        }

      case let .playLast(songId):
        return .run { send in
          await send(
            .playLastResponse(
              TaskResult { try await apiClient.addSongToCurrentPlaylist(songId, nil, "last") }
            )
          )
        }

      case let .playNowResponse(.success(song)):
        let insertIndex = state.insertSongNextToCurrent(song: song)
        return self.playOn(state: &state, index: insertIndex)

      case let .playNextResponse(.success(song)):
        _ = state.insertSongNextToCurrent(song: song)
        flashMessageClient.showLocalizedMessage("text.addedToPlaylist")

        return .none

      case let .playLastResponse(.success(song)):
        state.playlist.append(song)
        flashMessageClient.showLocalizedMessage("text.addedToPlaylist")

        return .none

      case let .deleteSongsResponse(.failure(error)),
        let .moveSongsResponse(.failure(error)),
        let .currentPlaylistResponse(.failure(error)),
        let .playSongsResponse(.failure(error)),
        let .playSongsBeginWithResponse(.failure(error), _),
        let .playNowResponse(.failure(error)),
        let .playNextResponse(.failure(error)),
        let .playLastResponse(.failure(error)),
        let .toggleFavoriteResponse(.failure(error)):
        guard let error = error as? APIClient.APIError else { return .none }

        if error == .unauthorized {
          AppStore.shared.send(.logout)
        } else {
          state.alert = .init(title: .init(error.localizedString))
        }

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
    case noRepeat
    case repead
    case single
    case shuffle

    var symbol: String {
      switch self {
      case .noRepeat:
        return "repeat"
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
