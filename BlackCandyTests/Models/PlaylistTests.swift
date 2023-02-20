import XCTest
@testable import BlackCandy

final class PlaylistTests: XCTestCase {
  var playlist: Playlist!
  var songs: [Song]!

  override func setUpWithError() throws {
    playlist = Playlist()
    songs = try fixtureData("songs")

    playlist.update(songs: songs)
  }

  func testUpdatePlaylist() throws {
    playlist.update(songs: [])
    XCTAssertEqual(playlist.songs, [])
  }

  func testGetShuffledSongs() throws {
    playlist.isShuffled = true
    XCTAssertNotEqual(playlist.songs, songs)
  }

  func testRemoveSongs() throws {
    let song = songs.first(where: { $0.id == 1 })!

    playlist.remove(songs: [song])
    XCTAssertFalse(playlist.songs.contains(song))

    playlist.isShuffled = true
    XCTAssertFalse(playlist.songs.contains(song))
  }

  func testInsertSong() throws {
    let song = songs.first(where: { $0.id == 1 })!

    playlist.remove(songs: [song])
    playlist.insert(song, at: 2)
    XCTAssertEqual(playlist.songs.map({ $0.id }), [2, 3, 1, 4, 5])

    playlist.isShuffled = true
    XCTAssertTrue(playlist.songs.contains(song))
  }

  func testGetIndex() throws {
    let song = songs.first(where: { $0.id == 1 })!
    XCTAssertEqual(playlist.index(of: song), 0)
  }

  func testGetIndexById() throws {
    XCTAssertEqual(playlist.index(by: 2), 1)
  }
}
