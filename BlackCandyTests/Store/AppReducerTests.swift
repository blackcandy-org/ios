import XCTest
import ComposableArchitecture
@testable import BlackCandy

@MainActor
final class AppReducerTests: XCTestCase {
  func testGetSystemInfo() async throws {
    let store = TestStore(initialState: AppReducer.State(), reducer: AppReducer())

    let serverAddressState = ServerAddressState()
    serverAddressState.url = "http://localhost:3000"

    let systemInfoResponse = SystemInfo(
      version: .init(major: 3, minor: 0, patch: 0, pre: ""),
      serverAddress: URL(string: "http://localhost:3000")
    )

    await store.send(.getSystemInfo(serverAddressState))

    await store.receive(.systemInfoResponse(.success(systemInfoResponse))) {
      $0.serverAddress = systemInfoResponse.serverAddress
      $0.isLoginViewVisible = true
    }
  }

  func testGetSystemInfoWithInvalidServerAddress() async throws {
    let store = TestStore(initialState: AppReducer.State(), reducer: AppReducer())

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
      TestStore(initialState: AppReducer.State(), reducer: AppReducer())
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
      TestStore(initialState: AppReducer.State(), reducer: AppReducer())
    }

    await store.send(.getSystemInfo(serverAddressState))

    await store.receive(.systemInfoResponse(.success(systemInfoResponse))) {
      $0.alert = .init(title: .init("text.unsupportedServer"))
    }
  }

  func testLogin() async throws {
    let store = TestStore(initialState: AppReducer.State(), reducer: AppReducer())

    let loginState = LoginState()
    loginState.email = "test@test.com"
    loginState.password = "foobar"

    let user = User(id: 1, email: "test@test.com", isAdmin: true)
    let cookie = HTTPCookie(properties: [
      .name: "testName",
      .value: "testValue",
      .originURL: URL(string: "http://localhost:3000")!,
      .path: "/"
    ])!

    let loginResponse = APIClient.AuthenticationResponse(token: "test_token", user: user, cookies: [cookie])

    await store.send(.login(loginState))

    await store.receive(.loginResponse(.success(loginResponse))) {
      $0.currentUser = user
    }

    XCTAssertTrue(store.state.isLoggedIn)
    XCTAssertTrue(store.state.isAdmin)
  }

  func testLoginFailed() async throws {
    let responseError = APIClient.APIError.unknown

    let store = withDependencies {
      $0.apiClient.authentication = { _ in
        throw responseError
      }
    } operation: {
      TestStore(initialState: AppReducer.State(), reducer: AppReducer())
    }

    let loginState = LoginState()
    loginState.email = "test@test.com"
    loginState.password = "foobar"

    await store.send(.login(loginState))

    await store.receive(.loginResponse(.failure(responseError))) {
      $0.alert = .init(title: .init(responseError.localizedString))
    }

    XCTAssertFalse(store.state.isLoggedIn)
    XCTAssertFalse(store.state.isAdmin)
  }

  func testRestoreStates() async throws {
    let store = TestStore(initialState: AppReducer.State(), reducer: AppReducer())

    await store.send(.restoreStates) {
      $0.serverAddress = URL(string: "http://localhost:3000")
      $0.currentUser = store.dependencies.jsonDataClient.currentUser()
    }
  }

  func testLogout() async throws {
    let user = User(id: 1, email: "test@test.com", isAdmin: true)
    var state = AppReducer.State()
    state.currentUser = user

    let store = TestStore(initialState: state, reducer: AppReducer())

    await store.send(.logout) {
      $0.currentUser = nil
    }
  }

  func testUpdateTheme() async throws {
    let store = TestStore(initialState: AppReducer.State(), reducer: AppReducer())

    await store.send(.updateTheme(.dark)) {
      $0.currentTheme = .dark
    }
  }

  func testUpdateAccountSheetVisible() async throws {
    let store = TestStore(initialState: AppReducer.State(), reducer: AppReducer())

    await store.send(.updateAccountSheetVisible(true)) {
      $0.isAccountSheetVisible = true
    }
  }

  func testUpdateLoginViewVisible() async throws {
    let store = TestStore(initialState: AppReducer.State(), reducer: AppReducer())

    await store.send(.updateLoginViewVisible(true)) {
      $0.isLoginViewVisible = true
    }
  }

  func testDismissAlert() async throws {
    var state = AppReducer.State()
    state.alert = .init(title: .init("test"))

    let store = TestStore(initialState: state, reducer: AppReducer())

    await store.send(.dismissAlert) {
      $0.alert = nil
    }
  }
}
