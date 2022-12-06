import SwiftUI
import ComposableArchitecture

struct PlayerControlView: View {
  let store: Store<AppState.PlayerState, AppAction.PlayerAction>
  let durationFormatter = DurationFormatter()

  var body: some View {
    WithViewStore(self.store) { viewStore in
      songProgress(viewStore)
      playerControl(viewStore)
        .padding(CustomStyle.spacing(.large))
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
            .tint(.primary)
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
              .tint(.primary)
              .customStyle(.largeSymbol)
          } else {
            Image(systemName: "play.fill")
              .tint(.primary)
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
            .tint(.primary)
            .customStyle(.largeSymbol)
        }
      )
    }
  }

  func songProgress(_ viewStore: ViewStore<AppState.PlayerState, AppAction.PlayerAction>) -> some View {
    let currentSong = viewStore.currentSong
    let noneDuration = "--:--"
    let duration = currentSong != nil ? durationFormatter.string(from: currentSong!.duration) : noneDuration
    let currentDuration = currentSong != nil ? durationFormatter.string(from: viewStore.currentTime) : noneDuration
    let progressValue = currentSong != nil ? viewStore.currentTime / currentSong!.duration : 0

    return VStack {
      PlayerSliderView(value: viewStore.binding(
        get: { _ in progressValue },
        send: { AppAction.PlayerAction.seekToRatio($0) }
      ))

      HStack {
        if viewStore.status == .loading {
          ProgressView()
            .customStyle(.playerProgressLoader)
        } else {
          Text(currentDuration!)
            .font(.caption2)
            .foregroundColor(.secondary)
        }

        Spacer()

        Text(duration!)
          .font(.caption2)
          .foregroundColor(.secondary)
      }
    }
  }
}
