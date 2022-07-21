import Foundation
import ComposableArchitecture
import Turbo

struct AppState: Equatable {
  var alert: AlertState<AppAction>?
  var serverAddress: URL?
  var currentSession: Session?
  var isLoginSheetVisible = false
}
