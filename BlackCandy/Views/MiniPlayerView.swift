import SwiftUI
import ComposableArchitecture

struct MiniPlayerView: View {
  let store: Store<AppState.PlayerState, AppAction.PlayerAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      HStack(spacing: 0) {
        HStack(spacing: CustomStyle.spacing(.medium)) {
          AsyncImage(url: viewStore.currentSong?.albumImageUrl.small) { image in
            image.resizable()
          } placeholder: {
            Color.secondary
          }
          .cornerRadius(CustomStyle.cornerRadius(.small))
          .frame(width: CustomStyle.miniPlayerImageSize, height: CustomStyle.miniPlayerImageSize)

          Text(viewStore.currentSong?.name ?? NSLocalizedString("label.notPlaying", comment: ""))
        }

        Spacer()

        HStack(spacing: CustomStyle.spacing(.medium)) {
          Button(
            action: {
              if viewStore.isPlaying {
                viewStore.send(.pause)
              } else {
                viewStore.send(.play)
              }
            },
            label: {
              if viewStore.isPlaying {
                Image(systemName: "pause.fill")
                  .foregroundColor(.primary)
              } else {
                Image(systemName: "play.fill")
                  .foregroundColor(.primary)
              }
            }
          )

          Button(
            action: {
              viewStore.send(.next)
            },
            label: {
              Image(systemName: "forward.fill")
                .foregroundColor(.primary)
            }
          )
        }
      }
      .padding(.horizontal)
      .padding(.vertical, CustomStyle.spacing(.narrow))
    }
  }
}
