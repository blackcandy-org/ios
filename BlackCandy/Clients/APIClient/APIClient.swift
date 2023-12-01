import Foundation
import Dependencies
import Alamofire

struct APIClient {
  var login: (LoginState) async throws -> AuthenticationResponse
  var logout: () async throws -> NoContentResponse
  var getSongsFromCurrentPlaylist: () async throws -> [Song]
  var addSongToFavorite: (Song) async throws -> Int
  var deleteSongInFavorite: (Song) async throws -> Int
  var deleteSongInCurrentPlaylist: (Song) async throws -> NoContentResponse
  var moveSongInCurrentPlaylist: (Int, Int) async throws -> NoContentResponse
  var getSong: (Int) async throws -> Song
  var getSystemInfo: (ServerAddressState) async throws -> SystemInfo
  var addSongToCurrentPlaylist: (Int, Song?, String?) async throws -> Song
  var replaceCurrentPlaylistWithAlbumSongs: (Int) async throws -> [Song]
  var replaceCurrentPlaylistWithPlaylistSongs: (Int) async throws -> [Song]
}

extension APIClient: TestDependencyKey {
  static let testValue = Self(
    login: unimplemented("\(Self.self).login"),

    logout: unimplemented("\(Self.self).logout"),

    getSongsFromCurrentPlaylist: unimplemented("\(Self.self).getSongsFromCurrentPlaylist"),

    addSongToFavorite: unimplemented("\(Self.self).addSongToFavorite"),

    deleteSongInFavorite: unimplemented("\(Self.self).deleteSongInFavorite"),

    deleteSongInCurrentPlaylist: { _ in
      NoContentResponse()
    },

    moveSongInCurrentPlaylist: { _, _ in
      NoContentResponse()
    },

    getSong: unimplemented("\(Self.self).getSong"),

    getSystemInfo: unimplemented("\(Self.self).getSystemInfo"),

    addSongToCurrentPlaylist: unimplemented("\(Self.self).addSongToCurrentPlaylist"),

    replaceCurrentPlaylistWithAlbumSongs: unimplemented("\(Self.self).replaceCurrentPlaylistWithAlbumSongs"),

    replaceCurrentPlaylistWithPlaylistSongs: unimplemented("\(Self.self).replaceCurrentPlaylistWithPlaylistSongs")
  )

  static let previewValue = testValue
}

extension DependencyValues {
  var apiClient: APIClient {
    get { self[APIClient.self] }
    set { self[APIClient.self] = newValue }
  }
}

extension APIClient {
  struct AuthenticationResponse: Equatable {
    let token: String
    let user: User
    let cookies: [HTTPCookie]
  }

  struct NoContentResponse: Codable, Equatable, EmptyResponse {
    static let value = NoContentResponse()
    static func emptyValue() -> APIClient.NoContentResponse {
      value
    }
  }

  enum APIError: Error, Equatable {
    case invalidRequest
    case invalidResponse
    case unauthorized
    case badRequest(String?)
    case unknown

    var localizedString: String {
      switch self {
      case .invalidRequest:
        return NSLocalizedString("text.invalidRequest", comment: "")

      case .invalidResponse:
        return NSLocalizedString("text.invalidResponse", comment: "")

      case .unauthorized:
        return NSLocalizedString("text.invalidUserCredential", comment: "")

      case let .badRequest(message):
        guard let message = message else {
          return NSLocalizedString("text.badRequest", comment: "")
        }

        return message

      case .unknown:
        return NSLocalizedString("text.unknownNetworkError", comment: "")
      }
    }
  }
}
