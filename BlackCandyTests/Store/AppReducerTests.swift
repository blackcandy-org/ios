import XCTest
import ComposableArchitecture
@testable import BlackCandy

@MainActor
final class AppReducerTests: XCTestCase {
  func testRestoreStates() async throws {
    let currentUser = try users(id: 1)

    let store = withDependencies {
      $0.jsonDataClient.currentUser = { currentUser }
    } operation: {
      TestStore(initialState: AppReducer.State(), reducer: AppReducer())
    }

    await store.send(.restoreStates) {
      $0.serverAddress = URL(string: "http://localhost:3000")
      $0.currentUser = currentUser
    }
  }

  func testLogout() async throws {
    var state = AppReducer.State()
    state.currentUser = try users(id: 1)

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

  func testDismissAlert() async throws {
    var state = AppReducer.State()
    state.alert = .init(title: .init("test"))

    let store = TestStore(initialState: state, reducer: AppReducer())

    await store.send(.dismissAlert) {
      $0.alert = nil
    }
  }
}
