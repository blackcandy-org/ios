import SwiftUI

struct ContentView: View {
  var body: some View {
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
  }
}
