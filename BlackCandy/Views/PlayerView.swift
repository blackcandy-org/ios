import SwiftUI
import ComposableArchitecture

struct PlayerView: View {
  let store: StoreOf<PlayerReducer>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      VStack {
        Spacer()

        if viewStore.isPlaylistVisible {
          PlayerPlaylistView(store: store)
        } else {
          PlayerSongInfoView(currentSong: viewStore.currentSong)
          PlayerControlView(store: store)
            .disabled(!viewStore.hasCurrentSong)
        }

        Spacer()

        PlayerActionsView(store: store)
      }
      .padding()
      .padding(.bottom, CustomStyle.spacing(.wide))
      .frame(maxWidth: CustomStyle.playerMaxWidth)
      .onAppear {
        viewStore.send(.getStatus)
        viewStore.send(.getCurrentTime)
      }
    }
  }
}
