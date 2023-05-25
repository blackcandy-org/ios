import Foundation
import Dependencies
import AVFoundation

struct PlayerClient {
  var hasCurrentItem: () -> Bool
  var playOn: (URL) -> Void
  var play: () -> Void
  var pause: () -> Void
  var replay: () -> Void
  var seek: (CMTime) -> Void
  var stop: () -> Void
  var getCurrentTime: () -> AsyncStream<Double>
  var getStatus: () -> AsyncStream<Status>
  var getPlaybackRate: () -> Float
}

extension PlayerClient: TestDependencyKey {
  static let testValue = Self(
    hasCurrentItem: unimplemented("\(Self.self).hasCurrentItem"),
    playOn: { _ in },
    play: { },
    pause: { },
    replay: {},
    seek: { _ in },
    stop: {},
    getCurrentTime: unimplemented("\(Self.self).getCurrentTime"),
    getStatus: unimplemented("\(Self.self).getStatus"),
    getPlaybackRate: { 1 }
  )
}

extension DependencyValues {
  var playerClient: PlayerClient {
    get { self[PlayerClient.self] }
    set { self[PlayerClient.self] = newValue }
  }
}

extension PlayerClient {
  enum Status: String {
    case pause
    case playing
    case loading
    case end
  }
}
