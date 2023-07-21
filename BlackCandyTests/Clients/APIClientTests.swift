import XCTest
import OHHTTPStubsSwift
import OHHTTPStubs
@testable import BlackCandy

final class APIClientTests: XCTestCase {
  var apiClient: APIClient!

  override func setUpWithError() throws {
    apiClient = APIClient.live()
  }

  override func tearDownWithError() throws {
    HTTPStubs.removeAllStubs()
  }

  func testGetSystemInfo() async throws {
    let responseJSON = """
    {
      "version": {
        "major": 3,
        "minor": 0,
        "patch": 0,
        "pre": "beta1"
      }
    }
    """.data(using: .utf8)!

    stub(condition: isPath("/api/v1/system")) { _ in
      return .init(data: responseJSON, statusCode: 200, headers: nil)
    }

    let serverAddressState = ServerAddressState()
    serverAddressState.url = "http://localhost:3000"

    let systemInfo = try await apiClient.getSystemInfo(serverAddressState)

    XCTAssertEqual(systemInfo.version.major, 3)
    XCTAssertEqual(systemInfo.version.minor, 0)
    XCTAssertEqual(systemInfo.version.patch, 0)
    XCTAssertEqual(systemInfo.version.pre, "beta1")
  }

  func testAuthentication() async throws {
    let responseJSON = """
    {
      "user": {
        "id": 1,
        "email": "admin@admin.com",
        "is_admin": true,
        "api_token": "fake_token"
      }
    }
    """.data(using: .utf8)!

    stub(condition: isMethodPOST() && isPath("/api/v1/authentication")) { _ in
      return .init(data: responseJSON, statusCode: 200, headers: ["set-cookie": "session=123456"])
    }

    let loginState = LoginState()
    loginState.email = "admin@admin.com"
    loginState.password = "foobar"

    let authenticationResponse = try await apiClient.authentication(loginState)
    let responseCookie = authenticationResponse.cookies.first!

    XCTAssertEqual(authenticationResponse.user.email, "admin@admin.com")
    XCTAssertEqual(authenticationResponse.token, "fake_token")
    XCTAssertEqual(responseCookie.name, "session")
    XCTAssertEqual(responseCookie.value, "123456")
  }

  func testGetCurrentPlaylistSongs() async throws {
    stub(condition: isPath("/api/v1/current_playlist/songs")) { _ in
      let stubPath = OHPathForFile("songs.json", type(of: self))
      return fixture(filePath: stubPath!, headers: nil)
    }

    let response = try await apiClient.getCurrentPlaylistSongs()

    XCTAssertEqual(response.count, 5)
  }

  func testToggleFavorite() async throws {
    let song = try songs(id: 1)

    stub(condition: isMethodPOST() && isPath("/api/v1/favorite_playlist/songs")) { _ in
      return .init(jsonObject: [] as [Any], statusCode: 200, headers: nil)
    }

    let response = try await apiClient.toggleFavorite(song)

    XCTAssertEqual(response.self, APIClient.NoContentResponse.value)
  }

  func testDeleteCurrentPlaylistSongs() async throws {
    let song = try songs(id: 1)

    stub(condition: isMethodDELETE() && isPath("/api/v1/current_playlist/songs")) { _ in
      return .init(jsonObject: [] as [Any], statusCode: 200, headers: nil)
    }

    let response = try await apiClient.deleteCurrentPlaylistSongs([song])

    XCTAssertEqual(response.self, APIClient.NoContentResponse.value)
  }

  func testMoveCurrentPlaylistSongs() async throws {
    stub(condition: isMethodPATCH() && isPath("/api/v1/current_playlist/songs")) { _ in
      return .init(jsonObject: [] as [Any], statusCode: 200, headers: nil)
    }

    let response = try await apiClient.moveCurrentPlaylistSongs(0, 1)

    XCTAssertEqual(response.self, APIClient.NoContentResponse.value)
  }

  func testGetSong() async throws {
    let responseJSON = """
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
    """.data(using: .utf8)!

    stub(condition: isPath("/api/v1/songs/1")) { _ in
      return .init(data: responseJSON, statusCode: 200, headers: nil)
    }

    let response = try await apiClient.getSong(1)

    XCTAssertEqual(response.id, 1)
    XCTAssertEqual(response.name, "sample1")
    XCTAssertEqual(response.isFavorited, false)
    XCTAssertEqual(response.albumImageUrl.small, URL(string: "http://localhost:3000/uploads/album/image/1/small.jpg"))
  }

  func testHandleUnauthorizedError() async throws {
    stub(condition: isPath("/api/v1/songs/1")) { _ in
      return .init(jsonObject: [] as [Any], statusCode: 401, headers: nil)
    }

    do {
      _ = try await apiClient.getSong(1)
    } catch {
      guard let error = error as? APIClient.APIError else {
        return XCTFail("Wrong type of APIError.")
      }

      XCTAssertEqual(error, APIClient.APIError.unauthorized)
    }
  }

  func testHandleBadRequestError() async throws {
    let errorMessage = "Invalide request"

    stub(condition: isPath("/api/v1/songs/1")) { _ in
      return .init(jsonObject: ["message": errorMessage], statusCode: 400, headers: nil)
    }

    do {
      _ = try await apiClient.getSong(1)
    } catch {
      guard let error = error as? APIClient.APIError else {
        return XCTFail("Wrong type of APIError.")
      }

      XCTAssertEqual(error, APIClient.APIError.badRequest(errorMessage))
    }
  }

  func testAddCurrentPlaylistSong() async throws {
    let responseJSON = """
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
    """.data(using: .utf8)!

    let currentSong = try songs(id: 2)

    stub(condition: isMethodPOST() && isPath("/api/v1/current_playlist/songs")) { _ in
      return .init(data: responseJSON, statusCode: 200, headers: nil)
    }

    let response = try await apiClient.addCurrentPlaylistSong(1, currentSong)

    XCTAssertEqual(response.id, 1)
    XCTAssertEqual(response.name, "sample1")
    XCTAssertEqual(response.isFavorited, false)
    XCTAssertEqual(response.albumImageUrl.small, URL(string: "http://localhost:3000/uploads/album/image/1/small.jpg"))
  }
}
