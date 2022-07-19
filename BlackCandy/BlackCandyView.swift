import SwiftUI
import ComposableArchitecture

struct BlackCandyView: View {
  let store: Store<AppState, AppAction>

  var body: some View {
    HomeView(store: store)
      .alert(self.store.scope(state: \.alert), dismiss: .dismissAlert)
  }
}
