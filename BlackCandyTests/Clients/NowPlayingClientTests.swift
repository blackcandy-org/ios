import XCTest
import MediaPlayer
import OHHTTPStubsSwift
import OHHTTPStubs
@testable import BlackCandy

final class NowPlayingClientTests: XCTestCase {
  var nowPlayingClient: NowPlayingClient!
  var playingSong: Song!

  override func setUpWithError() throws {
    nowPlayingClient = NowPlayingClient.liveValue
    playingSong = try songs(id: 1)
  }

  override func tearDownWithError() throws {
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    HTTPStubs.removeAllStubs()
  }

  func testUpdateNowPlayingInfo() async throws {
    stub(condition: isAbsoluteURLString(playingSong.albumImageUrl.large.absoluteString) ) { _ in
      return .init(fileAtPath: OHPathForFile("cover_image.jpg", type(of: self))!, statusCode: 200, headers: ["Content-Type": "image/jpeg"])
    }

    await nowPlayingClient.updateInfo(playingSong)

    let nowPlayingInfo =  MPNowPlayingInfoCenter.default().nowPlayingInfo
    XCTAssertEqual(nowPlayingInfo?[MPMediaItemPropertyTitle] as! String, playingSong.name)
    XCTAssertEqual(nowPlayingInfo?[MPMediaItemPropertyArtist] as! String, playingSong.artistName)
    XCTAssertEqual(nowPlayingInfo?[MPMediaItemPropertyAlbumTitle] as! String, playingSong.albumName)
    XCTAssertEqual(nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] as! Double, playingSong.duration)
    XCTAssertNotNil(nowPlayingInfo?[MPMediaItemPropertyArtwork] as! MPMediaItemArtwork)
  }

  func testUpdateNowPlayingPlaybackInfo() throws {
    nowPlayingClient.updatePlaybackInfo(1.5, 1)

    let nowPlayingInfo =  MPNowPlayingInfoCenter.default().nowPlayingInfo
    XCTAssertEqual(nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] as! Float, 1.5)
    XCTAssertEqual(nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] as! Float, 1)
  }
}
