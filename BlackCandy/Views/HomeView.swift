import SwiftUI
import ComposableArchitecture

struct HomeView: View {
  let store: Store<AppState, AppAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      if !viewStore.isLoggedIn {
        LoginView(store: store)
      } else {
        TabView {
          TurboView(viewStore: viewStore, path: "/")
            .tabItem {
              Label("label.home", systemImage: "house")
            }

          TurboView(viewStore: viewStore, path: "/library")
            .tabItem {
              Label("label.library", systemImage: "square.stack")
            }

          AccountView(store: store)
            .tabItem {
              Label("label.account", systemImage: "person")
            }
        }
        .environment(\.serverAddress, viewStore.serverAddress)
      }
    }
  }
}
