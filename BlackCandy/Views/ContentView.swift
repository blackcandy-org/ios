import SwiftUI
import ComposableArchitecture

struct ContentView: View {
  let store: StoreOf<AppReducer>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      if !viewStore.isLoggedIn {
        LoginView(store: store)
      } else {
        HomeView(store: store)
          .onAppear {
            viewStore.send(.player(.getCurrentPlaylist))
          }
          .preferredColorScheme(viewStore.currentTheme.colorScheme)
      }
    }
  }
}
