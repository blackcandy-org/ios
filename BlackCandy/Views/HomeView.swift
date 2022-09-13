import SwiftUI
import ComposableArchitecture
import LNPopupUI

struct HomeView: View {
  let store: Store<AppState, AppAction>
  @State var isPlayerPresented = true

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
        .popup(isBarPresented: $isPlayerPresented, popupContent: {
          PlayerView(store: store)
        })
        .popupBarCustomView(popupBarContent: {
          MiniPlayerView(currentSong: viewStore.currentSong)
        })
        .environment(\.serverAddress, viewStore.serverAddress)
      }
    }
  }
}
