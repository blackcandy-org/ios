import Foundation
import MediaPlayer
import ComposableArchitecture

struct RemoteControl {
  static func setup(store: StoreOf<PlayerReducer>) {
    let commandCenter = MPRemoteCommandCenter.shared()

    commandCenter.playCommand.addTarget { _ in
      store.send(.play)
      return .success
    }

    commandCenter.pauseCommand.addTarget { _ in
      store.send(.pause)
      return .success
    }

    commandCenter.stopCommand.addTarget { _ in
      store.send(.stop)
      return .success
    }

    commandCenter.togglePlayPauseCommand.addTarget { _ in
      if store.withState(\.isPlaying) {
        store.send(.pause)
      } else {
        store.send(.play)
      }

      return .success
    }

    commandCenter.nextTrackCommand.addTarget { _ in
      store.send(.next)
      return .success
    }

    commandCenter.previousTrackCommand.addTarget { _ in
      store.send(.previous)
      return .success
    }

    commandCenter.changePlaybackPositionCommand.addTarget { remoteEvent in
      guard let event = remoteEvent as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }

      store.send(.seekToPosition(event.positionTime))
      return .success
    }
  }
}
