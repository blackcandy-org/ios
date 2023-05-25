import Foundation
import Dependencies
import Alamofire

extension APIClient: DependencyKey {
  static func live(userDefaultClient: UserDefaultsClient, keychainClient: KeychainClient) -> Self {
    var headers: HTTPHeaders {
      var basicHeaders: HTTPHeaders = [
        .userAgent("Turbo Native iOS")
      ]

      if let token = keychainClient.apiToken() {
        basicHeaders.add(.authorization("Token \(token)"))
      }

      return basicHeaders
    }

    var jsonDecoder: JSONDecoder {
      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase

      return decoder
    }

    func requestURL(_ path: String) -> URL {
      userDefaultClient.serverAddress()!.appendingPathComponent(path)
    }

    func decodeJSON(_ data: Data) -> [String: Any]? {
      let json = try? JSONSerialization.jsonObject(with: data)
      return json as? [String: Any]
    }

    func handleRequest<T, V>(_ request: DataTask<V>, handle: (DataTask<V>, DataResponse<V, AFError>) async throws -> T) async throws -> T {
      let response = await request.response

      do {
        return try await handle(request, response)
      } catch {
        throw handleError(error, response.data)
      }
    }

    func handleError(_ error: Error, _ responseData: Data?) -> APIError {
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

    func handleUnacceptableStatusCode(_ code: Int, _ responseData: Data?) -> APIError {
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

    return Self(
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
            cookies: HTTPCookie.cookies(withResponseHeaderFields: responseHeaders, for: userDefaultClient.serverAddress()!)
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

  static let liveValue = live(userDefaultClient: UserDefaultsClient.liveValue, keychainClient: KeychainClient.liveValue)
}
