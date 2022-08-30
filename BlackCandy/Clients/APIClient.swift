import Foundation
import ComposableArchitecture

struct APIClient {
  var authentication: (LoginState) -> Effect<AuthenticationResponse, Error>

  struct AuthenticationResponse: Equatable {
    let serverAddress: URL
    let token: String
    let user: User
    let cookies: [HTTPCookie]
  }

  struct ResponseData {
    let json: [String: Any]
    let headers: [String: String]
  }

  enum Error: Swift.Error, Equatable {
    case invalidUserCredential
    case invalidRequest
    case invalidResponse
  }

  enum Response {
    case success(ResponseData)
    case failure(HTTPURLResponse)
    case error(Error)
  }

  static func request(_ url: URL, method: String = "GET", body: Data?) -> URLRequest {
    var request = URLRequest(url: url)

    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Turbo Native iOS", forHTTPHeaderField: "User-Agent")
    request.httpBody = body

    return request
  }

  static func parseResponse(data: Data?, response: URLResponse?, error: Swift.Error?) -> Response {
    guard error == nil, let response = response as? HTTPURLResponse else {
      return .error(.invalidRequest)
    }

    guard (200 ..< 300).contains(response.statusCode) else {
      return .failure(response)
    }

    guard
      let data = data,
      let json = decodeJSON(data),
      let headers = response.allHeaderFields as? [String: String] else {
      return .error(.invalidResponse)
    }

    return .success(ResponseData(json: json, headers: headers))
  }

  static func encodeJSON(_ value: [String: Any]) -> Data? {
    try? JSONSerialization.data(withJSONObject: value)
  }

  static func decodeJSON(_ data: Data) -> [String: Any]? {
    let json = try? JSONSerialization.jsonObject(with: data)
    return json as? [String: Any]
  }
}

extension APIClient {
  static let live = Self(
    authentication: { loginState in
      .future { callback in
        let serverAddress = URL(string: loginState.serverAddress)!
        var authenticationURL = URLComponents(
          url: serverAddress.appendingPathComponent("/api/v1/authentication"),
          resolvingAgainstBaseURL: false
        )!

        authenticationURL.queryItems = [URLQueryItem(name: "with_session", value: "true")]

        let body = encodeJSON(["user_session": ["email": loginState.email, "password": loginState.password]])

        let task = URLSession.shared.dataTask(with: request(authenticationURL.url!, method: "POST", body: body)) { data, response, error in
          let responseResult = parseResponse(data: data, response: response, error: error)

          switch responseResult {
          case .success(let responseData):
            let response = responseData.json["user"] as! [String: Any]

            let token = response["api_token"] as! String
            let id = response["id"] as! Int
            let email = response["email"] as! String
            let isAdmin = response["is_admin"] as! Bool

            callback(.success(AuthenticationResponse(
              serverAddress: serverAddress,
              token: token,
              user: User(id: id, email: email, isAdmin: isAdmin),
              cookies: HTTPCookie.cookies(withResponseHeaderFields: responseData.headers, for: serverAddress)
            )))
          case .failure(let response):
            if response.statusCode == 401 {
              callback(.failure(.invalidUserCredential))
            }
          case .error(let error):
            callback(.failure(error))
          }
        }

        task.resume()
      }
    }
  )
}
