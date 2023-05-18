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
}
