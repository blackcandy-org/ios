import Foundation
import ComposableArchitecture

struct AppStore {
  static let shared = Store(
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
}
