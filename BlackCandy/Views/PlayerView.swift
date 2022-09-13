import SwiftUI
import ComposableArchitecture

struct PlayerView: View {
  let store: Store<AppState, AppAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      VStack {
        if viewStore.hasPlaylistSongs {
          PlaylistView(songs: viewStore.playlist!.songs)
        } else {
          Text("label.noItems")
        }
      }
      .onAppear {
        viewStore.send(.getCurrentPlaylist)
      }
    }
  }
}
