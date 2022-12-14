import Foundation
import MediaPlayer
import ComposableArchitecture

struct RemoteControl {
  static let shared = RemoteControl()

  let viewStore = ViewStore(AppStore.shared, removeDuplicates: ==)

  func setup() {
    let commandCenter = MPRemoteCommandCenter.shared()

    commandCenter.playCommand.addTarget { _ in
      viewStore.send(.player(.play))
      return .success
    }

    commandCenter.pauseCommand.addTarget { _ in
      viewStore.send(.player(.pause))
      return .success
    }

    commandCenter.stopCommand.addTarget { _ in
      viewStore.send(.player(.stop))
      return .success
    }

    commandCenter.togglePlayPauseCommand.addTarget { _ in
      if viewStore.state.player.isPlaying {
        viewStore.send(.player(.pause))
      } else {
        viewStore.send(.player(.play))
      }

      return .success
    }

    commandCenter.nextTrackCommand.addTarget { _ in
      viewStore.send(.player(.next))
      return .success
    }

    commandCenter.previousTrackCommand.addTarget { _ in
      viewStore.send(.player(.previous))
      return .success
    }

    commandCenter.changePlaybackPositionCommand.addTarget { remoteEvent in
      guard let event = remoteEvent as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }

      viewStore.send(.player(.seekToPosition(event.positionTime)))
      return .success
    }

  }
}
