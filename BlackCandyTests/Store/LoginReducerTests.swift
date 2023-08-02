import XCTest
import ComposableArchitecture
@testable import BlackCandy

@MainActor
final class LoginReducerTests: XCTestCase {
  func testGetSystemInfo() async throws {
    let systemInfoResponse = SystemInfo(
      version: .init(major: 3, minor: 0, patch: 0, pre: ""),
      serverAddress: URL(string: "http://localhost:3000")
    )

    let store = withDependencies {
      $0.apiClient.getSystemInfo = { _ in
        systemInfoResponse
      }
    } operation: {
      TestStore(initialState: LoginReducer.State()) {
        LoginReducer()
      }
    }

    let serverAddressState = ServerAddressState()
    serverAddressState.url = "http://localhost:3000"

    await store.send(.getSystemInfo(serverAddressState))

    await store.receive(.systemInfoResponse(.success(systemInfoResponse))) {
      $0.serverAddress = systemInfoResponse.serverAddress
      $0.isAuthenticationViewVisible = true
    }
  }

  func testGetSystemInfoWithInvalidServerAddress() async throws {
    let store = TestStore(initialState: LoginReducer.State()) {
      LoginReducer()
    }

    let serverAddressState = ServerAddressState()
    serverAddressState.url = "invalid address"

    await store.send(.getSystemInfo(serverAddressState)) {
      $0.alert = .init(title: .init("text.invalidServerAddress"))
    }
  }

  func testSystemInfoResponseWithInvalidServerAddress() async throws {
    let serverAddressState = ServerAddressState()
    serverAddressState.url = "http://localhost:3000"

    let systemInfoResponse = SystemInfo(
      version: .init(major: 3, minor: 0, patch: 0, pre: ""),
      serverAddress: URL(string: "invalid address")
    )

    let store = withDependencies {
      $0.apiClient.getSystemInfo = { _ in
        systemInfoResponse
      }
    } operation: {
      TestStore(initialState: LoginReducer.State()) {
        LoginReducer()
      }
    }

    await store.send(.getSystemInfo(serverAddressState))

    await store.receive(.systemInfoResponse(.success(systemInfoResponse))) {
      $0.alert = .init(title: .init("text.invalidServerAddress"))
    }
  }

  func testSystemInfoResponseWithUnsupportedVersion() async throws {
    let serverAddressState = ServerAddressState()
    serverAddressState.url = "http://localhost:3000"

    let systemInfoResponse = SystemInfo(
      version: .init(major: 2, minor: 0, patch: 0, pre: ""),
      serverAddress: URL(string: "http://localhost:3000")
    )

    let store = withDependencies {
      $0.apiClient.getSystemInfo = { _ in
        systemInfoResponse
      }
    } operation: {
      TestStore(initialState: LoginReducer.State()) {
        LoginReducer()
      }
    }

    await store.send(.getSystemInfo(serverAddressState))

    await store.receive(.systemInfoResponse(.success(systemInfoResponse))) {
      $0.alert = .init(title: .init("text.unsupportedServer"))
    }
  }

  func testLogin() async throws {
    let user = try users(id: 1)
    let cookie = HTTPCookie(properties: [
      .name: "testName",
      .value: "testValue",
      .originURL: URL(string: "http://localhost:3000")!,
      .path: "/"
    ])!

    let loginResponse = APIClient.AuthenticationResponse(token: "test_token", user: user, cookies: [cookie])

    let store = withDependencies {
      $0.apiClient.authentication = { _ in
        loginResponse
      }
    } operation: {
      TestStore(initialState: LoginReducer.State()) {
        LoginReducer()
      }
    }

    let loginState = LoginState()
    loginState.email = "test@test.com"
    loginState.password = "foobar"

    await store.send(.login(loginState))

    await store.receive(.loginResponse(.success(loginResponse))) {
      $0.currentUser = user
    }
  }

  func testLoginFailed() async throws {
    let responseError = APIClient.APIError.unknown

    let store = withDependencies {
      $0.apiClient.authentication = { _ in
        throw responseError
      }
    } operation: {
      TestStore(initialState: LoginReducer.State()) {
        LoginReducer()
      }
    }

    let loginState = LoginState()
    loginState.email = "test@test.com"
    loginState.password = "foobar"

    await store.send(.login(loginState))

    await store.receive(.loginResponse(.failure(responseError))) {
      $0.alert = .init(title: .init(responseError.localizedString))
    }
  }
}
