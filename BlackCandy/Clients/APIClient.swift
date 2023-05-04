import Foundation
import ComposableArchitecture
import Alamofire

struct APIClient {
  private static var serverAddress: URL?
  private static var token: String?

  var updateServerAddress: (URL?) -> Void
  var updateToken: (String?) -> Void
  var authentication: (LoginState) async throws -> AuthenticationResponse
  var getCurrentPlaylistSongs: () async throws -> [Song]
  var toggleFavorite: (Song) async throws -> NoContentResponse
  var deleteCurrentPlaylistSongs: ([Song]) async throws -> NoContentResponse
  var moveCurrentPlaylistSongs: (Int, Int) async throws -> NoContentResponse
  var getSong: (Int) async throws -> Song
  var getSystemInfo: (ServerAddressState) async throws -> SystemInfo

  private static var headers: HTTPHeaders {
    var basicHeaders: HTTPHeaders = [
      .userAgent("Turbo Native iOS")
    ]

    if let token = Self.token {
      basicHeaders.add(.authorization("Token \(token)"))
    }

    return basicHeaders
  }

  private static var jsonDecoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    return decoder
  }

  private static func requestURL(_ path: String) -> URL {
    Self.serverAddress!.appendingPathComponent(path)
  }

  private static func decodeJSON(_ data: Data) -> [String: Any]? {
    let json = try? JSONSerialization.jsonObject(with: data)
    return json as? [String: Any]
  }

  private static func handleRequest<T, V>(_ request: DataTask<V>, handle: (DataTask<V>, DataResponse<V, AFError>) async throws -> T) async throws -> T {
    let response = await request.response

    do {
      return try await handle(request, response)
    } catch {
      throw handleError(error, response.data)
    }
  }

  private static func handleError(_ error: Error, _ responseData: Data?) -> APIError {
    guard let error = error as? AFError else { return .unknown }

    switch error {
    case .invalidURL,
      .parameterEncodingFailed,
      .parameterEncoderFailed,
      .requestAdaptationFailed:
      return .invalidRequest

    case .responseSerializationFailed:
      return .invalidResponse

    case let .responseValidationFailed(reason):
      switch reason {
      case let .unacceptableStatusCode(code):
        return handleUnacceptableStatusCode(code, responseData)
      default:
        return .invalidResponse
      }

    default:
      return .unknown
    }
  }

  private static func handleUnacceptableStatusCode(_ code: Int, _ responseData: Data?) -> APIError {
    switch code {
    case 401:
      return .unauthorized

    case 400:
      guard let data = responseData,
        let errorMessage = decodeJSON(data)?["message"] as? String else {
        return .badRequest(nil)
      }

      return .badRequest(errorMessage)

    default:
      return .invalidResponse
    }
  }
}

extension APIClient {
  static let live = Self(
    updateServerAddress: { serverAddress in
      Self.serverAddress = serverAddress
    },

    updateToken: { token in
      Self.token = token
    },

    authentication: { loginState in
      let parameters: [String: Any] = [
        "with_session": "true",
        "user_session": [
          "email": loginState.email,
          "password": loginState.password
        ]
      ]

      let request = AF.request(
        requestURL("/api/v1/authentication"),
        method: .post,
        parameters: parameters,
        headers: headers
      )
      .validate()
      .serializingData()

      return try await handleRequest(request) { request, response in
        let value = try await request.value
        let jsonData = decodeJSON(value)?["user"] as! [String: Any]
        let token = jsonData["api_token"] as! String
        let id = jsonData["id"] as! Int
        let email = jsonData["email"] as! String
        let isAdmin = jsonData["is_admin"] as! Bool
        let responseHeaders = response.response?.allHeaderFields as! [String: String]

        return AuthenticationResponse(
          token: token,
          user: User(id: id, email: email, isAdmin: isAdmin),
          cookies: HTTPCookie.cookies(withResponseHeaderFields: responseHeaders, for: Self.serverAddress!)
        )
      }
    },

    getCurrentPlaylistSongs: {
      let request = AF.request(
        requestURL("/api/v1/current_playlist/songs"),
        headers: headers
      )
      .validate()
      .serializingDecodable([Song].self, decoder: jsonDecoder)

      return try await handleRequest(request) { request, _ in
        try await request.value
      }
    },

    toggleFavorite: { song in
      let request = AF.request(
        requestURL("/api/v1/favorite_playlist/songs"),
        method: song.isFavorited ? .delete : .post,
        parameters: ["song_id": song.id],
        headers: headers
      )
      .validate()
      .serializingDecodable(NoContentResponse.self)

      return try await handleRequest(request) { request, _ in
        try await request.value
      }
    },

    deleteCurrentPlaylistSongs: { songs in
      let request = AF.request(
        requestURL("/api/v1/current_playlist/songs"),
        method: .delete,
        parameters: ["song_ids": songs.map { $0.id }],
        headers: headers
      )
      .validate()
      .serializingDecodable(NoContentResponse.self)

      return try await handleRequest(request) { request, _ in
        try await request.value
      }
    },

    moveCurrentPlaylistSongs: { fromPosition, toPosition in
      let request = AF.request(
        requestURL("/api/v1/current_playlist/songs"),
        method: .patch,
        parameters: ["from_position": fromPosition, "to_position": toPosition],
        headers: headers
      )
      .validate()
      .serializingDecodable(NoContentResponse.self)

      return try await handleRequest(request) { request, _ in
        try await request.value
      }
    },

    getSong: { songId in
      let request = AF.request(
        requestURL("/api/v1/songs/\(songId)"),
        headers: headers
      )
      .validate()
      .serializingDecodable(Song.self, decoder: jsonDecoder)

      return try await handleRequest(request) { request, _ in
        try await request.value
      }
    },

    getSystemInfo: { serverAddressState in
      let url = "\(serverAddressState.url)/api/v1/system"

      let request = AF.request(
        url,
        headers: headers
      )
      .validate()
      .serializingDecodable(SystemInfo.self, decoder: jsonDecoder)

      return try await handleRequest(request) { request, response in
        var systemInfo = try await request.value
        var serverAddressUrlComponents = URLComponents(url: (response.response?.url)!, resolvingAgainstBaseURL: false)!
        serverAddressUrlComponents.path = ""
        systemInfo.serverAddress = serverAddressUrlComponents.url

        return systemInfo
      }
    }
  )
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
