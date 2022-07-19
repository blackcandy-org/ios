import ComposableArchitecture

enum AppAction: Equatable {
  case dismissAlert
  case login(SessionState)
}

let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, _ in
  switch action {
  case let .login(sessionState):
    if sessionState.hasValidServerAddress {
      return .none
    } else {
      state.alert = .init(title: .init("text.invalidServerAddress"))
      return .none
    }

  case .dismissAlert:
    state.alert = nil
    return .none
  }
}
