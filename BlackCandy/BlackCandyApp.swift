import SwiftUI
import ComposableArchitecture

@main
struct BlackCandyApp: App {
  var body: some Scene {
    WindowGroup {
      BlackCandyView(store: Store(
        initialState: AppState(),
        reducer: appReducer,
        environment: AppEnvironment(
          mainQueue: .main,
          apiClient: .live,
          userDefaultsClient: .live,
          cookiesClient: .live
        )
      ))
    }
  }
}
