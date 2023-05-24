import XCTest
import ComposableArchitecture
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
        reducer: PlayerReducer()
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
      reducer: PlayerReducer()
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
    var playlist = Playlist()
    let songs = try songs()

    playlist.update(songs: songs)

    let store = withDependencies {
      $0.playerClient.hasCurrentItem = { false }
    } operation: {
      TestStore(
        initialState: PlayerReducer.State(
          playlist: playlist,
          currentSong: songs.first
        ),
        reducer: PlayerReducer()
      )
    }

    await store.send(.play)
    await store.receive(.playOn(0))
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
        reducer: PlayerReducer()
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
        reducer: PlayerReducer()
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
        reducer: PlayerReducer()
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
      reducer: PlayerReducer()
    )

    await store.send(.playOn(0)) {
      $0.currentSong = songs.first
    }

    await store.send(.next)

    await store.receive(.playOn(1)) {
      $0.currentSong = songs[1]
    }
  }

  func testPlayPreviousSong() async throws {
    var playlist = Playlist()
    let songs = try songs()

    playlist.update(songs: songs)

    let store = TestStore(
      initialState: PlayerReducer.State(playlist: playlist),
      reducer: PlayerReducer()
    )

    await store.send(.playOn(1)) {
      $0.currentSong = songs[1]
    }

    await store.send(.previous)

    await store.receive(.playOn(0)) {
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
        reducer: PlayerReducer()
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
}
