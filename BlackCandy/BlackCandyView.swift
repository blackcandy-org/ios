import SwiftUI
import ComposableArchitecture

struct BlackCandyView: View {
  let store: Store<AppState, AppAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      TabView {
        TurboView(path: "/albums")
          .tabItem {
            Label("Albums", systemImage: "square.stack")
          }

        TurboView(path: "/artists")
          .tabItem {
            Label("Artists", systemImage: "music.mic")
          }

        TurboView(path: "/songs")
          .tabItem {
            Label("Songs", systemImage: "music.note")
          }

        TurboView(path: "/setting")
          .tabItem {
            Label("Settings", systemImage: "gear")
          }
      }
      .environment(\.serverAddress, viewStore.serverAddress)
    }
  }
}
