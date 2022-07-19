import SwiftUI
import ComposableArchitecture

struct HomeView: View {
  let store: Store<AppState, AppAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      if viewStore.serverAddress.isEmpty {
        SessionNewView(store: store)
      } else {
        TabView {
          TurboView(store: store, path: "/albums")
            .tabItem {
              Label("Albums", systemImage: "square.stack")
            }

          TurboView(store: store, path: "/artists")
            .tabItem {
              Label("Artists", systemImage: "music.mic")
            }

          TurboView(store: store, path: "/songs")
            .tabItem {
              Label("Songs", systemImage: "music.note")
            }

          TurboView(store: store, path: "/setting")
            .tabItem {
              Label("Settings", systemImage: "gear")
            }
        }
        .environment(\.serverAddress, viewStore.serverAddress)
      }
    }
  }
}
