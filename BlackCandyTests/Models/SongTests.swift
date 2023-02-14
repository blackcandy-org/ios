import XCTest
@testable import BlackCandy

final class SongTests: XCTestCase {
  func testDecodeSong() throws {
    let json = """
      {
        "id":1,
        "name":"sample1",
        "duration": 129.0,
        "url":"http://localhost:3000/api/v1/stream/new?song_id=1",
        "album_name":"sample album",
        "artist_name":"sample artist",
        "is_favorited":false,
        "format":"mp3",
        "album_image_url":{
          "small":"http://localhost:3000/uploads/album/image/1/small.jpg",
          "medium":"http://localhost:3000/uploads/album/image/1/medium.jpg",
          "large":"http://localhost:3000/uploads/album/image/1/large.jpg"
        }
      }
    """

    let song: Song = try decodeJSON(from: json)

    XCTAssertEqual(song.id, 1)
    XCTAssertEqual(song.name, "sample1")
    XCTAssertEqual(song.isFavorited, false)
    XCTAssertEqual(song.albumImageUrl.small, URL(string: "http://localhost:3000/uploads/album/image/1/small.jpg"))
  }
}
