import Foundation
import AVFAudio
import ComposableArchitecture

class AudioSessionControl {
  static func setup(store: StoreOf<AppReducer>) {
    let audioSession = AVAudioSession.sharedInstance()
    let notificationCenter = NotificationCenter.default
    let audioSessionControl = AudioSessionControl(store: store)

    try? audioSession.setCategory(.playback)

    notificationCenter.addObserver(
      audioSessionControl,
      selector: #selector(handleInterruption),
      name: AVAudioSession.interruptionNotification,
      object: audioSession
    )

    notificationCenter.addObserver(
      audioSessionControl,
      selector: #selector(handleRouteChange),
      name: AVAudioSession.routeChangeNotification,
      object: nil
    )
  }

  let viewStore: ViewStore<Void, AppReducer.Action>

  init(store: StoreOf<AppReducer>) {
    self.viewStore = ViewStore(store.stateless, removeDuplicates: ==)
  }

  @objc func handleInterruption(notification: Notification) {
    guard
      let userInfo = notification.userInfo,
      let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
      let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
      return
    }

    switch type {
    case .began:
      viewStore.send(.player(.pause))
    case .ended:
      // An interruption ended. Resume playback, if appropriate.
      guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }

      let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)

      if options.contains(.shouldResume) {
        viewStore.send(.player(.play))
      }

    default:
      viewStore.send(.player(.pause))
    }
  }

  @objc func handleRouteChange(notification: Notification) {
    guard
      let userInfo = notification.userInfo,
      let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
      let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
      return
    }

    switch reason {
    case .newDeviceAvailable: () // New device found.
    case .oldDeviceUnavailable: // Old device removed.
      guard let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription else {
        return
      }

      if hasHeadphones(in: previousRoute) {
        viewStore.send(.player(.pause))
      }

    default: ()
    }
  }

  func hasHeadphones(in routeDescription: AVAudioSessionRouteDescription) -> Bool {
    // Filter the outputs to only those with a port type of headphones.
    return !routeDescription.outputs.filter({ $0.portType == .headphones }).isEmpty
  }
}
