import SwiftUI
import ComposableArchitecture

struct PlayerActionsView: View {
  let store: Store<AppState.PlayerState, AppAction.PlayerAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      HStack {
        Button(
          action: {},
          label: {
            Image(systemName: "repeat")
              .foregroundColor(viewStore.isPlaylistVisible ? Color.init(.systemGray2) : .primary)
          }
        )
        .padding(CustomStyle.spacing(.tiny))
        .disabled(viewStore.isPlaylistVisible)

        Spacer()

        Button(
          action: {
            viewStore.send(.toggleFavorite)
          },
          label: {
            if viewStore.currentSong?.isFavorited ?? false {
              Image(systemName: "heart.fill")
                .foregroundColor(viewStore.isPlaylistVisible ? Color.init(.systemGray2) : .red)
            } else {
              Image(systemName: "heart")
                .foregroundColor(viewStore.isPlaylistVisible ? Color.init(.systemGray2) : .primary)
            }
          }
        )
        .padding(CustomStyle.spacing(.tiny))
        .disabled(viewStore.isPlaylistVisible)

        Spacer()

        Button(
          action: {
            viewStore.send(.togglePlaylistVisible)
          },
          label: {
            Image(systemName: "list.bullet")
              .foregroundColor(.primary)
          }
        )
        .padding(CustomStyle.spacing(.tiny))
        .background(viewStore.isPlaylistVisible ? Color.init(.systemGray3) : Color.clear)
        .cornerRadius(CustomStyle.cornerRadius(.small))
      }
    }
    .padding(.horizontal, CustomStyle.spacing(.large))
  }
}
