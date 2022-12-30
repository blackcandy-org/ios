import SwiftUI
import ComposableArchitecture

struct HomeView: View {
  let store: StoreOf<AppReducer>

  var body: some View {
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
    }
    .player(with: store)
  }
}
