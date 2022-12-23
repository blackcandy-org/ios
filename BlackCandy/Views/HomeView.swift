import SwiftUI
import ComposableArchitecture

struct HomeView: View {
  let store: StoreOf<AppReducer>
  @Environment(\.horizontalSizeClass) var horizontalSizeClass

  var body: some View {
    if horizontalSizeClass == .regular {
      SidebarView(sidebar: {
        VStack {
          SidebarNavigationView()
          Divider()
          PlayerView(store: self.store.scope(
            state: \.player,
            action: AppReducer.Action.player
          ))
          .padding()
        }
        .background(Color.init(.systemGroupedBackground))
      }, detail: {
        TurboView(path: "/")
      })
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
      }
      .player(with: store)
    }
  }
}
