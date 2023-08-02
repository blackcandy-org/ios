import Foundation
import ComposableArchitecture

struct AppStore {
  static let shared = Store(initialState: AppReducer.State()) {
    AppReducer()
  }
}
