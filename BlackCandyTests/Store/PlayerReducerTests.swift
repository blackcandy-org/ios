import XCTest
import ComposableArchitecture
import CoreMedia
@testable import BlackCandy

@MainActor
final class PlayerReducerTests: XCTestCase {
  func testPlaySong() async throws {
    let getStatusTask = AsyncStream.makeStream(of: PlayerClient.Status.self)

    var playlist = Playlist()
    let songs = try songs()

    playlist.update(songs: songs)

    let store = withDependencies {
      $0.playerClient.getStatus = { getStatusTask.stream }
      $0.playerClient.playOn = { _ in getStatusTask.continuation.yield(.playing) }
    } operation: {
      TestStore(
        initialState: PlayerReducer.State(playlist: playlist),
        reducer: { PlayerReducer() }
      )
    }

    await store.send(.playOn(0)) {
      $0.currentSong = songs.first
    }

    await store.send(.getStatus)

    await store.receive(.handleStatusChange(.playing)) {
      $0.status = .playing
    }

    getStatusTask.continuation.finish()
    await store.finish()
  }

  func testPlaySongOutOfIndexRange() async throws {
    var playlist = Playlist()
    let songs = try songs()

    playlist.update(songs: songs)

    let store = TestStore(
      initialState: PlayerReducer.State(playlist: playlist),
      reducer: { PlayerReducer() }
    )

    await store.send(.playOn(-1)) {
      $0.currentSong = songs.last
    }

    XCTAssertEqual(store.state.currentIndex, songs.count - 1)

    await store.send(.playOn(songs.count + 1)) {
      $0.currentSong = songs.first
    }

    XCTAssertEqual(store.state.currentIndex, 0)
  }

  func testPlayCurrentSong() async throws {
    let getStatusTask = AsyncStream.makeStream(of: PlayerClient.Status.self)

    var playlist = Playlist()
    let songs = try songs()

    playlist.update(songs: songs)

    let store = withDependencies {
      $0.playerClient.hasCurrentItem = { false }
      $0.playerClient.getStatus = { getStatusTask.stream }
      $0.playerClient.playOn = { _ in getStatusTask.continuation.yield(.playing) }
    } operation: {
      TestStore(
        initialState: PlayerReducer.State(
          playlist: playlist,
          currentSong: songs.first
        ),
        reducer: { PlayerReducer() }
      )
    }

    await store.send(.play)
    await store.send(.getStatus)

    await store.receive(.handleStatusChange(.playing)) {
      $0.status = .playing
    }

    getStatusTask.continuation.finish()
    await store.finish()
  }

  func testPlayPausedSong() async throws {
    let getStatusTask = AsyncStream.makeStream(of: PlayerClient.Status.self)

    let store = withDependencies {
      $0.playerClient.hasCurrentItem = { true }
      $0.playerClient.getStatus = { getStatusTask.stream }
      $0.playerClient.play = { getStatusTask.continuation.yield(.playing) }
    } operation: {
      TestStore(
        initialState: PlayerReducer.State(),
        reducer: { PlayerReducer() }
      )
    }

    await store.send(.play)
    await store.send(.getStatus)

    await store.receive(.handleStatusChange(.playing)) {
      $0.status = .playing
    }

    getStatusTask.continuation.finish()
    await store.finish()
  }

  func testPauseSong() async throws {
    let getStatusTask = AsyncStream.makeStream(of: PlayerClient.Status.self)

    let store = withDependencies {
      $0.playerClient.getStatus = { getStatusTask.stream }
      $0.playerClient.pause = { getStatusTask.continuation.yield(.pause) }
    } operation: {
      TestStore(
        initialState: PlayerReducer.State(status: .playing),
        reducer: { PlayerReducer() }
      )
    }

    await store.send(.pause)
    await store.send(.getStatus)

    await store.receive(.handleStatusChange(.pause)) {
      $0.status = .pause
    }

    getStatusTask.continuation.finish()
    await store.finish()
  }

  func testStopSong() async throws {
    let getStatusTask = AsyncStream.makeStream(of: PlayerClient.Status.self)
    let currentSong = try songs(id: 1)

    let store = withDependencies {
      $0.playerClient.getStatus = { getStatusTask.stream }
      $0.playerClient.stop = { getStatusTask.continuation.yield(.pause) }
    } operation: {
      TestStore(
        initialState: PlayerReducer.State(
          currentSong: currentSong,
          status: .playing
        ),
        reducer: { PlayerReducer() }
      )
    }

    await store.send(.stop) {
      $0.currentSong = nil
    }

    await store.send(.getStatus)

    await store.receive(.handleStatusChange(.pause)) {
      $0.status = .pause
    }

    getStatusTask.continuation.finish()
    await store.finish()
  }

  func testPlayNextSong() async throws {
    var playlist = Playlist()
    let songs = try songs()

    playlist.update(songs: songs)

    let store = TestStore(
      initialState: PlayerReducer.State(playlist: playlist),
      reducer: { PlayerReducer() }
    )

    await store.send(.playOn(0)) {
      $0.currentSong = songs.first
    }

    await store.send(.next) {
      $0.currentSong = songs[1]
    }
  }

  func testPlayPreviousSong() async throws {
    var playlist = Playlist()
    let songs = try songs()

    playlist.update(songs: songs)

    let store = TestStore(
      initialState: PlayerReducer.State(playlist: playlist),
      reducer: { PlayerReducer() }
    )

    await store.send(.playOn(1)) {
      $0.currentSong = songs[1]
    }

    await store.send(.previous) {
      $0.currentSong = songs.first
    }
  }

  func testGetCurrentTime() async throws {
    let getCurrentTimeTask = AsyncStream.makeStream(of: Double.self)

    let store = withDependencies {
      $0.playerClient.getCurrentTime = { getCurrentTimeTask.stream }
    } operation: {
      TestStore(
        initialState: PlayerReducer.State(),
        reducer: { PlayerReducer() }
      )
    }

    await store.send(.getCurrentTime)

    getCurrentTimeTask.continuation.yield(2.5)
    getCurrentTimeTask.continuation.finish()

    await store.receive(.updateCurrentTime(2.5)) {
      $0.currentTime = 2.5
    }

    await store.finish()
  }

  func testToggleFavorite() async throws {
    var playlist = Playlist()
    let songs = try songs()
    let currentSong = songs.first!

    playlist.update(songs: songs)

    let store = withDependencies {
      $0.apiClient.addSongToFavorite = { _ in currentSong.id }
    } operation: {
      TestStore(
        initialState: PlayerReducer.State(
          playlist: playlist,
          currentSong: currentSong
        ),
        reducer: { PlayerReducer() }
      )
    }

    store.exhaustivity = .off

    await store.send(.toggleFavorite)

    await store.receive(.toggleFavoriteResponse(.success(currentSong.id))) {
      $0.currentSong?.isFavorited = true
    }
  }

  func testToogleFavoriteFailed() async throws {
    let currenSong = try songs(id: 1)
    let responseError = APIClient.APIError.unknown

    let store = withDependencies {
      $0.apiClient.addSongToFavorite = { _ in throw responseError }
    } operation: {
      TestStore(
        initialState: PlayerReducer.State(
          currentSong: currenSong
        ),
        reducer: { PlayerReducer() }
      )
    }

    store.exhaustivity = .off

    await store.send(.toggleFavorite)

    await store.receive(.toggleFavoriteResponse(.failure(responseError))) {
      $0.currentSong?.isFavorited = false
      $0.alert = .init(title: .init(responseError.localizedString))
    }
  }

  func testTogglePlaylistVisible() async throws {
    let store = TestStore(
      initialState: PlayerReducer.State(),
      reducer: { PlayerReducer() }
    )

    await store.send(.togglePlaylistVisible) {
      $0.isPlaylistVisible = true
    }
  }

  func testSeekToRatio() async throws {
    let currenSong = try songs(id: 1)
    let store = TestStore(
      initialState: PlayerReducer.State(
        currentSong: currenSong
      ),
      reducer: { PlayerReducer() }
    )

    let seekRation = 0.5

    await store.send(.seekToRatio(seekRation))
    await store.receive(.seekToPosition(currenSong.duration * seekRation))
  }

  func testSeekToPosition() async throws {
    let getCurrentTimeTask = AsyncStream.makeStream(of: Double.self)
    let currenSong = try songs(id: 1)

    let store = withDependencies {
      $0.playerClient.getCurrentTime = { getCurrentTimeTask.stream }
      $0.playerClient.seek = { time in
        getCurrentTimeTask.continuation.yield(time.seconds)
        getCurrentTimeTask.continuation.finish()
      }
    } operation: {
      TestStore(
        initialState: PlayerReducer.State(
          currentSong: currenSong
        ),
        reducer: { PlayerReducer() }
      )
    }

    let seekPosition = currenSong.duration * 0.5
    let seekTime = CMTime(seconds: seekPosition, preferredTimescale: 1)

    await store.send(.seekToPosition(seekPosition))
    await store.send(.getCurrentTime)

    await store.receive(.updateCurrentTime(seekTime.seconds)) {
      $0.currentTime = seekTime.seconds
    }

    await store.finish()
  }

  func testWillPlayNextSongAfterSongEnded() async throws {
    let getStatusTask = AsyncStream.makeStream(of: PlayerClient.Status.self)

    let store = withDependencies {
      $0.playerClient.getStatus = { getStatusTask.stream }
    } operation: {
      TestStore(
        initialState: PlayerReducer.State(),
        reducer: { PlayerReducer() }
      )
    }

    store.exhaustivity = .off

    await store.send(.getStatus)

    getStatusTask.continuation.yield(.end)
    getStatusTask.continuation.finish()

    await store.receive(.next)
  }

  func testWillPlayRepeatedlyAfterSongEndedWhenPlayModeIsSingle() async throws {
    let getStatusTask = AsyncStream.makeStream(of: PlayerClient.Status.self)
    var playlist = Playlist()
    let songs = try songs()

    playlist.update(songs: songs)

    let store = withDependencies {
      $0.playerClient.getStatus = { getStatusTask.stream }
      $0.playerClient.replay = {
        getStatusTask.continuation.yield(.playing)
        getStatusTask.continuation.finish()
      }
    } operation: {
      TestStore(
        initialState: PlayerReducer.State(
          playlist: playlist,
          currentSong: songs.first,
          mode: .single
        ),
        reducer: { PlayerReducer() }
      )
    }

    await store.send(.getStatus)

    getStatusTask.continuation.yield(.end)

    await store.receive(.handleStatusChange(.end)) {
      $0.status = .end
    }

    await store.receive(.handleStatusChange(.playing)) {
      $0.status = .playing
    }

    XCTAssertEqual(store.state.currentSong, songs.first)
  }

  func testToggleNextMode() async throws {
    let store = TestStore(
      initialState: PlayerReducer.State(
        mode: .repead
      ),
      reducer: { PlayerReducer() }
    )

    await store.send(.nextMode) {
      $0.mode = .single
    }

    await store.send(.nextMode) {
      $0.mode = .shuffle
      $0.playlist.isShuffled = true
    }
  }

  func testDeleteSongs() async throws {
    var playlist = Playlist()
    let songs = try songs()

    playlist.update(songs: songs)

    let store = TestStore(
      initialState: PlayerReducer.State(playlist: playlist),
      reducer: { PlayerReducer() }
    )

    store.exhaustivity = .off

    await store.send(.deleteSongs(.init(arrayLiteral: 0, 1)))

    XCTAssertFalse(store.state.playlist.songs.contains(where: { [1, 2].contains($0.id) }))
  }

  func testDeleteCurrentPlayingSong() async throws {
    let getStatusTask = AsyncStream.makeStream(of: PlayerClient.Status.self)
    var playlist = Playlist()
    let songs = try songs()

    playlist.update(songs: songs)

    let store = withDependencies {
      $0.playerClient.getStatus = { getStatusTask.stream }
      $0.playerClient.stop = {
        getStatusTask.continuation.yield(.pause)
        getStatusTask.continuation.finish()
      }
    } operation: {
      TestStore(
        initialState: PlayerReducer.State(
          playlist: playlist,
          currentSong: songs.first,
          status: .playing
        ),
        reducer: { PlayerReducer() }
      )
    }

    store.exhaustivity = .off

    await store.send(.getStatus)
    await store.send(.deleteSongs(.init(arrayLiteral: 0))) {
      $0.currentSong = songs[1]
    }

    await store.receive(.handleStatusChange(.pause))

    XCTAssertFalse(store.state.playlist.songs.contains(where: { $0.id == 1 }))
  }

  func testMoveSong() async throws {
    var playlist = Playlist()
    let songs = try songs()

    playlist.update(songs: songs)

    let store = TestStore(
      initialState: PlayerReducer.State(playlist: playlist),
      reducer: { PlayerReducer() }
    )

    store.exhaustivity = .off

    await store.send(.moveSongs(.init(arrayLiteral: 0), 2))

    XCTAssertEqual(store.state.playlist.songs.map({$0.id}), [2, 1, 3, 4, 5])
  }

  func testGetCurrentPlaylist() async throws {
    let songs = try songs()
    let store = withDependencies {
      $0.apiClient.getSongsFromCurrentPlaylist = { songs }
    } operation: {
      TestStore(
        initialState: PlayerReducer.State(),
        reducer: { PlayerReducer() }
      )
    }

    store.exhaustivity = .off

    await store.send(.getCurrentPlaylist)

    await store.receive(.currentPlaylistResponse(.success(songs))) {
      $0.playlist.orderedSongs = songs
      $0.currentSong = songs.first
    }
  }

  func testPlayAllSongFromAlbum() async throws {
    let songs = try songs()
    let store = withDependencies {
      $0.apiClient.replaceCurrentPlaylistWithAlbumSongs = { _ in songs }
    } operation: {
      TestStore(
        initialState: PlayerReducer.State(),
        reducer: { PlayerReducer() }
      )
    }

    store.exhaustivity = .off

    await store.send(.playAll("album", 1))

    await store.receive(.playAllResponse(.success(songs))) {
      $0.playlist.orderedSongs = songs
      $0.currentSong = songs.first
    }
  }

  func testPlayAllSongFromPlaylists() async throws {
    let songs = try songs()
    let store = withDependencies {
      $0.apiClient.replaceCurrentPlaylistWithPlaylistSongs = { _ in songs }
    } operation: {
      TestStore(
        initialState: PlayerReducer.State(),
        reducer: { PlayerReducer() }
      )
    }

    store.exhaustivity = .off

    await store.send(.playAll("playlist", 1))

    await store.receive(.playAllResponse(.success(songs))) {
      $0.playlist.orderedSongs = songs
      $0.currentSong = songs.first
    }
  }

  func testPlaySongInPlaylist() async throws {
    var playlist = Playlist()
    let songs = try songs()

    playlist.update(songs: songs)

    let store = TestStore(
      initialState: PlayerReducer.State(playlist: playlist),
      reducer: { PlayerReducer() }
    )

    await store.send(.playSong(1)) {
      $0.currentSong = songs.first
    }
  }

  func testPlaySongNotInPlaylist() async throws {
    var playlist = Playlist()
    let song = try songs(id: 1)
    let playingSong = try songs(id: 2)

    playlist.update(songs: [song])

    let store = withDependencies {
      $0.apiClient.getSong = { _ in  playingSong }
      $0.apiClient.addSongToCurrentPlaylist = { _, _, _ in playingSong}
    } operation: {
      TestStore(
        initialState: PlayerReducer.State(playlist: playlist),
        reducer: { PlayerReducer() }
      )
    }

    store.exhaustivity = .off

    await store.send(.playSong(2))

    await store.receive(.playSongResponse(.success(playingSong))) {
      $0.playlist.orderedSongs = [song, playingSong]
      $0.currentSong = playingSong
    }
  }

  func testAddSongIntoEmptyPlaylist() async throws {
    let song = try songs(id: 1)

    let store = withDependencies {
      $0.apiClient.getSong = { _ in song }
      $0.apiClient.addSongToCurrentPlaylist = { _, _, _ in song }
    } operation: {
      TestStore(
        initialState: PlayerReducer.State(),
        reducer: { PlayerReducer() }
      )
    }

    store.exhaustivity = .off

    await store.send(.playSong(1))

    await store.receive(.playSongResponse(.success(song))) {
      $0.playlist.orderedSongs = [song]
      $0.currentSong = song
    }
  }
}
