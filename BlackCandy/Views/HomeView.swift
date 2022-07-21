import SwiftUI
import ComposableArchitecture

struct HomeView: View {
  let store: Store<AppState, AppAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      if viewStore.serverAddress == nil {
        LoginView(store: store)
      } else {
        TabView {
          TurboView(viewStore: viewStore, path: "/albums")
            .tabItem {
              Label("Albums", systemImage: "square.stack")
            }

          TurboView(viewStore: viewStore, path: "/artists")
            .tabItem {
              Label("Artists", systemImage: "music.mic")
            }

          TurboView(viewStore: viewStore, path: "/songs")
            .tabItem {
              Label("Songs", systemImage: "music.note")
            }

          TurboView(viewStore: viewStore, path: "/setting")
            .tabItem {
              Label("Settings", systemImage: "gear")
            }
        }
        .sheet(isPresented: viewStore.binding(
          get: { $0.isLoginSheetVisible },
          send: { AppAction.updateLoginSheetVisibility($0) }
        )) {
          LoginView(store: store)
            .alert(self.store.scope(state: \.alert), dismiss: .dismissAlert)
        }
        .environment(\.serverAddress, viewStore.serverAddress)
      }
    }
  }
}
