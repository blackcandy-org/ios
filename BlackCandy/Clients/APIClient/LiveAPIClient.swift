import Foundation
import Dependencies
import Alamofire

extension APIClient: DependencyKey {
  static func live() -> Self {
    @Dependency(\.userDefaultsClient) var userDefaultClient
    @Dependency(\.keychainClient) var keychainClient

    lazy var session: Session = {
      let configuration = URLSessionConfiguration.af.default

      configuration.waitsForConnectivity = true
      configuration.timeoutIntervalForResource = 300

      return Session(configuration: configuration)
    }()

    var headers: HTTPHeaders {
      var basicHeaders: HTTPHeaders = [
        .userAgent(BLACK_CANDY_USER_AGENT)
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
      userDefaultClient.serverAddress()!.appendingPathComponent("/api/v1\(path)")
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
      login: { loginState in
        let parameters: [String: Any] = [
          "with_cookie": "true",
          "session": [
            "email": loginState.email,
            "password": loginState.password
          ]
        ]

        let request = session.request(
          requestURL("/authentication"),
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

      logout: {
        let request = session.request(
          requestURL("/authentication"),
          method: .delete,
          headers: headers
        )
          .validate()
          .serializingDecodable(NoContentResponse.self)

        return try await handleRequest(request) { request, _ in
          try await request.value
        }
      },

      getSongsFromCurrentPlaylist: {
        let request = session.request(
          requestURL("/current_playlist/songs"),
          headers: headers
        )
          .validate()
          .serializingDecodable([Song].self, decoder: jsonDecoder)

        return try await handleRequest(request) { request, _ in
          try await request.value
        }
      },

      addSongToFavorite: { song in
        let request = session.request(
          requestURL("/favorite_playlist/songs"),
          method: .post,
          parameters: ["song_id": song.id],
          headers: headers
        )
          .validate()
          .serializingData()

        return try await handleRequest(request) { request, _ in
          let value = try await request.value
          return decodeJSON(value)?["id"] as! Int
        }
      },

      deleteSongInFavorite: { song in
        let request = session.request(
          requestURL("/favorite_playlist/songs/\(song.id)"),
          method: .delete,
          headers: headers
        )
          .validate()
          .serializingData()

        return try await handleRequest(request) { request, _ in
          let value = try await request.value
          return decodeJSON(value)?["id"] as! Int
        }
      },

      deleteSongInCurrentPlaylist: { song in
        let request = session.request(
          requestURL("/current_playlist/songs/\(song.id)"),
          method: .delete,
          headers: headers
        )
          .validate()
          .serializingDecodable(NoContentResponse.self)

        return try await handleRequest(request) { request, _ in
          try await request.value
        }
      },

      moveSongInCurrentPlaylist: { songId, destinationSongId in
        let request = session.request(
          requestURL("/current_playlist/songs/\(songId)/move"),
          method: .put,
          parameters: ["destination_song_id": destinationSongId],
          headers: headers
        )
          .validate()
          .serializingDecodable(NoContentResponse.self)

        return try await handleRequest(request) { request, _ in
          try await request.value
        }
      },

      getSong: { songId in
        let request = session.request(
          requestURL("/songs/\(songId)"),
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

        let request = session.request(
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
      },

      addSongToCurrentPlaylist: { songId, currentSong, location in
        var parameters: [String: Any] = ["song_id": songId]

        if let currentSongId = currentSong?.id {
          parameters["current_song_id"] = currentSongId
        }

        if let location = location {
          parameters["location"] = location
        }

        let request = session.request(
          requestURL("/current_playlist/songs"),
          method: .post,
          parameters: parameters,
          headers: headers
        )
          .validate()
          .serializingDecodable(Song.self, decoder: jsonDecoder)

        return try await handleRequest(request) { request, _ in
          try await request.value
        }
      },

      replaceCurrentPlaylistWithAlbumSongs: { albumId in
        let request = session.request(
          requestURL("/current_playlist/songs/albums/\(albumId)"),
          method: .put,
          headers: headers
        )
          .validate()
          .serializingDecodable([Song].self, decoder: jsonDecoder)

        return try await handleRequest(request) { request, _ in
          try await request.value
        }
      },

      replaceCurrentPlaylistWithPlaylistSongs: { playlistId in
        let request = session.request(
          requestURL("/current_playlist/songs/playlists/\(playlistId)"),
          method: .put,
          headers: headers
        )
          .validate()
          .serializingDecodable([Song].self, decoder: jsonDecoder)

        return try await handleRequest(request) { request, _ in
          try await request.value
        }
      }
    )
  }

  static let liveValue = live()
}
