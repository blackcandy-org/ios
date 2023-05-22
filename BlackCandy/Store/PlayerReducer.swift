import Foundation
import ComposableArchitecture
import CoreMedia

struct PlayerReducer: ReducerProtocol {
  @Dependency(\.apiClient) var apiClient
  @Dependency(\.playerClient) var playerClient
  @Dependency(\.nowPlayingClient) var nowPlayingClient
  @Dependency(\.cookiesClient) var cookiesClient

  struct State: Equatable {
    var alert: AlertState<AppReducer.Action>?
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

  func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case .play:
      if playerClient.hasCurrentItem() {
        playerClient.play()
        return .none
      } else {
        return .task { [currentIndex = state.currentIndex] in
          .playOn(currentIndex)
        }
      }

    case .pause:
      playerClient.pause()
      return .none

    case .stop:
      state.currentSong = nil
      playerClient.stop()

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
        state.currentSong = state.playlist.songs.last
      } else {
        state.currentSong = state.playlist.songs[index]
      }

      guard let currentSong = state.currentSong else { return .none }

      cookiesClient.createCookie("current_song_id", String(currentSong.id), nil)
      playerClient.playOn(currentSong.url)
      nowPlayingClient.updateInfo(currentSong)

      return .none

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

      return .task {
        await .toggleFavoriteResponse(TaskResult { try await apiClient.toggleFavorite(currentSong) })
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

      return .task {
        .seekToPosition(position)
      }

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
        return .task { .next }
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

      return .task {
        await .deleteSongsResponse(TaskResult { try await apiClient.deleteCurrentPlaylistSongs(songs) })
      }

    case let .moveSongs(fromOffsets, toOffset):
      guard let fromIndex = fromOffsets.first else { return .none }
      let movedSong = state.playlist.orderedSongs[fromIndex]

      state.playlist.orderedSongs.move(fromOffsets: fromOffsets, toOffset: toOffset)

      guard let toIndex = state.playlist.orderedSongs.firstIndex(of: movedSong) else { return .none }

      return .task {
        await .moveSongsResponse(TaskResult { try await apiClient.moveCurrentPlaylistSongs(fromIndex + 1, toIndex + 1) })
      }

    case .deleteSongsResponse(.success), .moveSongsResponse(.success):
      return .none

    case .getCurrentPlaylist:
      return .task {
        await .currentPlaylistResponse(TaskResult { try await apiClient.getCurrentPlaylistSongs() })
      }

    case let .currentPlaylistResponse(.success(songs)):
      state.playlist.update(songs: songs)
      state.currentSong = songs.first

      return .none

    case .playAll:
      return .task {
        await .playAllResponse(TaskResult { try await apiClient.getCurrentPlaylistSongs() })
      }

    case let .playAllResponse(.success(songs)):
      state.playlist.update(songs: songs)
      state.currentSong = songs.first

      return .task {
        .playOn(0)
      }

    case let .playSong(songId):
      if let songIndex = state.playlist.index(by: songId) {
        return .task {
          .playOn(songIndex)
        }
      } else {
        return .task {
          await .playSongResponse(TaskResult { try await apiClient.getSong(songId) })
        }
      }

    case let .playSongResponse(.success(song)):
      let insertIndex = state.currentIndex + 1
      state.playlist.insert(song, at: insertIndex)

      return .task {
        .playOn(insertIndex)
      }

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
