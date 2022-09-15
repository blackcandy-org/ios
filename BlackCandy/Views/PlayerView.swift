import SwiftUI
import ComposableArchitecture

struct PlayerView: View {
  let store: Store<AppState.PlayerState, AppAction.PlayerAction>
  let durationFormatter = DurationFormatter()

  var body: some View {
    WithViewStore(self.store) { viewStore in
      VStack {
        Spacer()

        albumImage(viewStore.currentSong)

        songInfo(viewStore.currentSong)
          .padding(.top, CustomStyle.spacing(.extraWide))
          .padding(.bottom, CustomStyle.spacing(.wide))

        VStack {
          songProgress(viewStore.currentSong)
            .padding(.bottom, CustomStyle.spacing(.large))

          playerControl(viewStore)
            .padding(.horizontal, CustomStyle.spacing(.large))
        }

        Spacer()

        playerActions
          .padding(.horizontal, CustomStyle.spacing(.large))
      }
      .padding(.bottom, CustomStyle.spacing(.wide))
      .frame(maxWidth: CustomStyle.playerMaxWidth)
    }
  }

  func albumImage(_ currentSong: Song?) -> some View {
    AsyncImage(url: currentSong?.albumImageUrl.large) { image in
      image.resizable()
    } placeholder: {
      Color.secondary
    }
    .cornerRadius(CustomStyle.cornerRadius(.medium))
    .frame(width: CustomStyle.playerImageSize, height: CustomStyle.playerImageSize)
  }

  func songInfo(_ currentSong: Song?) -> some View {
    VStack(spacing: CustomStyle.spacing(.tiny)) {
      Text(currentSong?.name ?? NSLocalizedString("label.notPlaying", comment: ""))
        .font(.headline)
      Text(currentSong?.artistName ?? "")
        .font(.caption)
    }
  }

  func songProgress(_ currentSong: Song?) -> some View {
    let duration = currentSong != nil ? durationFormatter.string(from: TimeInterval(currentSong!.duration)) : "--:--"

    return VStack {
      ProgressView()
        .progressViewStyle(.linear)

      HStack {
        Text(currentSong != nil ? "0:00" : "--:--")
          .font(.caption2)
          .foregroundColor(.secondary)

        Spacer()

        Text(duration!)
          .font(.caption2)
          .foregroundColor(.secondary)
      }
    }
  }

  func playerControl(_ viewStore: ViewStore<AppState.PlayerState, AppAction.PlayerAction>) -> some View {
    HStack {
      Button(
        action: {},
        label: {
          Image(systemName: "backward.fill")
            .foregroundColor(.primary)
            .customStyle(.largeSymbol)
        }
      )

      Spacer()

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
              .customStyle(.largeSymbol)
          } else {
            Image(systemName: "play.fill")
              .foregroundColor(.primary)
              .customStyle(.largeSymbol)
          }
        }
      )
      Spacer()

      Button(
        action: {},
        label: {
          Image(systemName: "forward.fill")
            .foregroundColor(.primary)
            .customStyle(.largeSymbol)
        }
      )
    }
  }

  var playerActions: some View {
    HStack {
      Button(
        action: {},
        label: {
          Image(systemName: "repeat")
            .foregroundColor(.primary)
        }
      )

      Spacer()

      Button(
        action: {},
        label: {
          Image(systemName: "heart")
            .foregroundColor(.primary)
        }
      )

      Spacer()

      Button(
        action: {},
        label: {
          Image(systemName: "list.bullet")
            .foregroundColor(.primary)
        }
      )
    }
  }
}
