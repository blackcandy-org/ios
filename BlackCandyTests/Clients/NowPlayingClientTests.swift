import XCTest
import MediaPlayer
import OHHTTPStubsSwift
import OHHTTPStubs
@testable import BlackCandy

final class NowPlayingClientTests: XCTestCase {
  var nowPlayingClient: NowPlayingClient!
  var playingSong: Song!

  override func setUpWithError() throws {
    let songs: [Song] = try fixtureData("songs")

    nowPlayingClient = NowPlayingClient.liveValue
    playingSong = songs.first(where: { $0.id == 1 })!
  }

  override func tearDownWithError() throws {
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    HTTPStubs.removeAllStubs()
  }

  func testUpdateNowPlayingInfo() throws {
    nowPlayingClient.updateInfo(playingSong)

    let nowPlayingInfo =  MPNowPlayingInfoCenter.default().nowPlayingInfo
    XCTAssertEqual(nowPlayingInfo?[MPMediaItemPropertyTitle] as! String, playingSong.name)
    XCTAssertEqual(nowPlayingInfo?[MPMediaItemPropertyArtist] as! String, playingSong.artistName)
    XCTAssertEqual(nowPlayingInfo?[MPMediaItemPropertyAlbumTitle] as! String, playingSong.albumName)
    XCTAssertEqual(nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] as! Double, playingSong.duration)
  }

  func testUpdateNowPlayingPlaybackInfo() throws {
    nowPlayingClient.updatePlaybackInfo(1.5, 1)

    let nowPlayingInfo =  MPNowPlayingInfoCenter.default().nowPlayingInfo
    XCTAssertEqual(nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] as! Float, 1.5)
    XCTAssertEqual(nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] as! Float, 1)
  }

  func testUpdateAlbumImageToNowPlayingInfo() throws {
    stub(condition: isPath("/cover_image.jpg") ) { _ in
      return .init(fileAtPath: OHPathForFile("cover_image.jpg", type(of: self))!, statusCode: 200, headers: ["Content-Type": "image/jpeg"])
    }

    let expectation = XCTestExpectation(description: "Update album image to info")

    NowPlayingClient.updateAlbumImage(url: URL(string: "http://localhost:3000/cover_image.jpg")!) {
      let nowPlayingInfo =  MPNowPlayingInfoCenter.default().nowPlayingInfo
      XCTAssertNotNil(nowPlayingInfo?[MPMediaItemPropertyArtwork] as! MPMediaItemArtwork)

      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 10.0)
  }
}
