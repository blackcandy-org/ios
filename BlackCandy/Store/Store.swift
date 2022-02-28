import Combine

class Store: ObservableObject {
  @Published var state = AppState()

  func dispatch(_ action: Actions) {
    action.execute(in: self)
  }

  func commit(_ mutation: Mutations) {
    mutation.execute(in: &state)
  }
}
