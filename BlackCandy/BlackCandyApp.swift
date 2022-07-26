import SwiftUI
import ComposableArchitecture

@main
struct BlackCandyApp: App {
  private let store = Store(
    initialState: AppState(),
    reducer: appReducer,
    environment: AppEnvironment(
      mainQueue: .main,
      apiClient: .live,
      userDefaultsClient: .live,
      cookiesClient: .live,
      keychainClient: .live
    )
  )

  init() {
    ViewStore(store.stateless, removeDuplicates: ==).send(.restoreStates)
  }

  var body: some Scene {
    WindowGroup {
      HomeView(store: store)
        .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
    }
  }
}
