import SwiftUI
import ComposableArchitecture

struct PlayerView: View {
  let store: Store<AppState.PlayerState, AppAction.PlayerAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      VStack {
        Spacer()
        if viewStore.isPlaylistVisible {
          PlayerPlaylistView(store: store)
        } else {
          PlayerSongInfoView(currentSong: viewStore.currentSong)
          PlayerControlView(store: store)
        }

        Spacer()

        PlayerActionsView(store: store)
      }
      .padding(.bottom, CustomStyle.spacing(.wide))
      .frame(maxWidth: CustomStyle.playerMaxWidth)
    }
  }
}
