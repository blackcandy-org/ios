import Foundation
import Dependencies
import Alamofire

struct APIClient {
  var updateServerAddress: (URL?) -> Void
  var updateToken: (String?) -> Void
  var authentication: (LoginState) async throws -> AuthenticationResponse
  var getCurrentPlaylistSongs: () async throws -> [Song]
  var toggleFavorite: (Song) async throws -> NoContentResponse
  var deleteCurrentPlaylistSongs: ([Song]) async throws -> NoContentResponse
  var moveCurrentPlaylistSongs: (Int, Int) async throws -> NoContentResponse
  var getSong: (Int) async throws -> Song
  var getSystemInfo: (ServerAddressState) async throws -> SystemInfo
}

extension APIClient: TestDependencyKey {
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
