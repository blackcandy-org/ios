import SwiftUI
import ComposableArchitecture

@main
struct BlackCandyApp: App {
  private let store = Store(
    initialState: AppState(),
    reducer: appReducer,
    environment: AppEnvironment(
      apiClient: .live,
      userDefaultsClient: .live,
      cookiesClient: .live,
      keychainClient: .live,
      jsonDataClient: .live,
      playerClient: .live
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
