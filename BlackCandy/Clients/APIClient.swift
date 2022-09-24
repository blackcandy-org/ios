import Foundation
import ComposableArchitecture
import Alamofire

struct APIClient {
  static var serverAddress: URL?
  static var token: String?

  var updateServerAddress: (URL?) -> Void
  var updateToken: (String?) -> Void
  var authentication: (LoginState) async throws -> AuthenticationResponse
  var currentPlaylistSongs: () async throws -> [Song]
  var toggleFavorite: (Song) async throws -> NoContentResponse

  struct AuthenticationResponse: Equatable {
    let serverAddress: URL
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

  static var headers: HTTPHeaders {
    var basicHeaders: HTTPHeaders = [
      .userAgent("Turbo Native iOS")
    ]

    if let token = Self.token {
      basicHeaders.add(.authorization("Token \(token)"))
    }

    return basicHeaders
  }

  static var jsonDecoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    return decoder
  }

  static func requestURL(_ path: String) -> URL {
    Self.serverAddress!.appendingPathComponent(path)
  }

  static func decodeJSON(_ data: Data) -> [String: Any]? {
    let json = try? JSONSerialization.jsonObject(with: data)
    return json as? [String: Any]
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
      let serverAddress = loginState.serverAddress
      let url = "\(serverAddress)/api/v1/authentication?with_session=true"

      let parameters: [String: [String: String]] = [
        "user_session": [
          "email": loginState.email,
          "password": loginState.password
        ]
      ]

      let request = AF.request(
        url,
        method: .post,
        parameters: parameters,
        encoder: JSONParameterEncoder.default,
        headers: headers
      )
      .validate()
      .serializingData()

      let response = await request.response
      let value = try await request.value

      let jsonData = decodeJSON(value)?["user"] as! [String: Any]
      let token = jsonData["api_token"] as! String
      let id = jsonData["id"] as! Int
      let email = jsonData["email"] as! String
      let isAdmin = jsonData["is_admin"] as! Bool
      let serverAddressUrl = URL(string: serverAddress)!
      let responseHeaders = response.response?.allHeaderFields as! [String: String]

      return AuthenticationResponse(
        serverAddress: serverAddressUrl,
        token: token,
        user: User(id: id, email: email, isAdmin: isAdmin),
        cookies: HTTPCookie.cookies(withResponseHeaderFields: responseHeaders, for: serverAddressUrl)
      )
    },

    currentPlaylistSongs: {
      let request = AF.request(
        requestURL("/api/v1/current_playlist/songs"),
        headers: headers
      )
      .validate()
      .serializingDecodable([Song].self, decoder: jsonDecoder)

      return try await request.value
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

      return try await request.value
    }
  )
}
