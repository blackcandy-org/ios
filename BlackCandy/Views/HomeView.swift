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
          TurboView(path: "/")
            .ignoresSafeArea(edges: .vertical)
            .tabItem {
              Label("label.home", systemImage: "house")
            }

          TurboView(path: "/library", hasSearchBar: true)
            .ignoresSafeArea(edges: .vertical)
            .tabItem {
              Label("label.library", systemImage: "square.stack")
            }

          AccountView(store: store)
            .tabItem {
              Label("label.account", systemImage: "person")
            }
        }
        .onAppear {
          viewStore.send(.player(.getCurrentPlaylist))
        }
        .popup(isBarPresented: $isPlayerPresented, popupContent: {
          PlayerView(store: self.store.scope(
            state: \.playerState,
            action: AppAction.player
          ))
        })
        .popupBarCustomView(popupBarContent: {
          MiniPlayerView(store: self.store.scope(
            state: \.playerState,
            action: AppAction.player
          ))
        })
        .environment(\.serverAddress, viewStore.serverAddress)
        .preferredColorScheme(viewStore.currentTheme.colorScheme)
      }
    }
  }
}
