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

        songProgress(viewStore)

        playerControl(viewStore)
          .padding(CustomStyle.spacing(.large))

        Spacer()

        playerActions(viewStore)
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

  func songProgress(_ viewStore: ViewStore<AppState.PlayerState, AppAction.PlayerAction>) -> some View {
    let currentSong = viewStore.currentSong
    let noneDuration = "--:--"
    let duration = currentSong != nil ? durationFormatter.string(from: currentSong!.duration) : noneDuration
    let currentDuration = currentSong != nil ? durationFormatter.string(from: viewStore.currentTime) : noneDuration
    let progressValue = currentSong != nil ? viewStore.currentTime / currentSong!.duration : 0

    return VStack {
      ProgressView(value: progressValue)
        .progressViewStyle(.linear)

      HStack {
        Text(currentDuration!)
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
        action: {
          viewStore.send(.previous)
        },
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
        action: {
          viewStore.send(.next)
        },
        label: {
          Image(systemName: "forward.fill")
            .foregroundColor(.primary)
            .customStyle(.largeSymbol)
        }
      )
    }
  }

  func playerActions(_ viewStore: ViewStore<AppState.PlayerState, AppAction.PlayerAction>) -> some View {
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
        action: {
          viewStore.send(.toggleFavorite)
        },
        label: {
          if viewStore.currentSong?.isFavorited ?? false {
            Image(systemName: "heart.fill")
              .foregroundColor(.red)
          } else {
            Image(systemName: "heart")
              .foregroundColor(.primary)
          }
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
