import SwiftUI
import ComposableArchitecture

struct PlayerControlView: View {
  let store: StoreOf<PlayerReducer>
  let durationFormatter = DurationFormatter()

  var body: some View {
    WithViewStore(self.store, observe: { $0 }, content: { viewStore in
      VStack {
        songProgress(viewStore)
        playerControl(viewStore)
          .padding(CustomStyle.spacing(.large))
      }
    })
  }

  func playerControl(_ viewStore: ViewStore<PlayerReducer.State, PlayerReducer.Action>) -> some View {
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
              .customStyle(.extraLargeSymbol)
          } else {
            Image(systemName: "play.fill")
              .tint(.primary)
              .customStyle(.extraLargeSymbol)
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

  func songProgress(_ viewStore: ViewStore<PlayerReducer.State, PlayerReducer.Action>) -> some View {
    let currentSong = viewStore.currentSong
    let noneDuration = "--:--"
    let duration = currentSong != nil ? durationFormatter.string(from: currentSong!.duration) : noneDuration
    let currentDuration = currentSong != nil ? durationFormatter.string(from: viewStore.currentTime) : noneDuration
    let progressValue = currentSong != nil ? viewStore.currentTime / currentSong!.duration : 0

    return VStack {
      PlayerSliderView(value: viewStore.binding(
        get: { _ in progressValue },
        send: { PlayerReducer.Action.seekToRatio($0) }
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

struct PlayerControlView_Previews: PreviewProvider {
  static var previews: some View {
    let song = Song(
      id: 0,
      name: "Hi Hi",
      duration: 120,
      url: URL(string: "http:localhost")!,
      albumName: "Test",
      artistName: "Test artist",
      format: "mp3",
      albumImageUrl: .init(
        small: URL(string: "http:localhost")!,
        medium: URL(string: "http:localhost")!,
        large: URL(string: "http:localhost")!),
      isFavorited: true
    )

    PlayerControlView(
      store: Store(initialState: PlayerReducer.State(
        currentSong: song
      )) {}
    )
  }
}
