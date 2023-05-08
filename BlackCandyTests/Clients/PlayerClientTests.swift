import XCTest
import OHHTTPStubsSwift
import OHHTTPStubs
import CoreMedia
@testable import BlackCandy

final class PlayerClientTests: XCTestCase {
  var playerClient: PlayerClient!

  override func setUpWithError() throws {
    playerClient = PlayerClient.live
    playerClient.updateAPIToken("test_token")

    stub(condition: isPath("/song.mp3") ) { _ in
      return .init(fileAtPath: OHPathForFile("song.mp3", type(of: self))!, statusCode: 200, headers: ["Content-Type": "audio/mpeg"])
    }
  }

  override func tearDownWithError() throws {
    HTTPStubs.removeAllStubs()
  }

  func testPlaySong() async throws {
    var playerStatus: [PlayerClient.Status] = []

    playerClient.playOn(URL(string: "http://localhost:3000/song.mp3")!)

    for await status in playerClient.getStatus().dropFirst().prefix(2) {
      playerStatus.append(status)
    }

    XCTAssertEqual(playerStatus, [.loading, .playing])
  }

  func testPauseSong() async throws {
    var playerStatus: [PlayerClient.Status] = []

    playerClient.playOn(URL(string: "http://localhost:3000/song.mp3")!)

    for await status in playerClient.getStatus().dropFirst().prefix(3) {
      playerStatus.append(status)

      if status == .playing {
        playerClient.pause()
      }
    }

    XCTAssertEqual(playerStatus, [.loading, .playing, .pause])
  }

  func testSeek() async throws {
    let time = CMTime(seconds: 2, preferredTimescale: 1)

    playerClient.playOn(URL(string: "http://localhost:3000/song.mp3")!)
    playerClient.seek(time)

    for await currentTime in playerClient.getCurrentTime().prefix(1) {
      XCTAssertEqual(currentTime, 2)
    }
  }

  func testReplay() async throws {
    let time = CMTime(seconds: 2, preferredTimescale: 1)

    playerClient.playOn(URL(string: "http://localhost:3000/song.mp3")!)
    playerClient.seek(time)
    playerClient.replay()

    for await currentTime in playerClient.getCurrentTime().prefix(1) {
      XCTAssertEqual(currentTime, 0)
    }
  }

  func testStop() async throws {
    var playerStatus: [PlayerClient.Status] = []
    var times: [Double] = []

    playerClient.playOn(URL(string: "http://localhost:3000/song.mp3")!)

    for await status in playerClient.getStatus().dropFirst().prefix(3) {
      playerStatus.append(status)

      if status == .playing {
        for await currentTime in playerClient.getCurrentTime().prefix(1) {
          times.append(currentTime)
        }

        playerClient.stop()
      }
    }

    XCTAssertEqual(playerStatus, [.loading, .playing, .pause])
    XCTAssertEqual(times, [0])
  }

  func testHasCurrentItem() throws {
    XCTAssertFalse(playerClient.hasCurrentItem())

    playerClient.playOn(URL(string: "http://localhost:3000/song.mp3")!)

    XCTAssertTrue(playerClient.hasCurrentItem())
  }

  func testGetPlaybackRate() throws {
    XCTAssertEqual(playerClient.getPlaybackRate(), 0)

    playerClient.playOn(URL(string: "http://localhost:3000/song.mp3")!)

    XCTAssertEqual(playerClient.getPlaybackRate(), 1)
  }

  func testWillGetEndStatusAfterEnd() async throws {
    var playerStatus: [PlayerClient.Status] = []

    playerClient.playOn(URL(string: "http://localhost:3000/song.mp3")!)

    for await status in playerClient.getStatus().dropFirst().prefix(3) {
      playerStatus.append(status)
    }

    XCTAssertEqual(playerStatus, [.loading, .playing, .end])
  }
}
