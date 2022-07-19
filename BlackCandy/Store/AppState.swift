import ComposableArchitecture
import Foundation

struct AppState: Equatable {
  var alert: AlertState<AppAction>?
  var serverAddress = ""
}
