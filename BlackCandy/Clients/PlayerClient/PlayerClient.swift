import Foundation
import Dependencies
import AVFoundation

struct PlayerClient {
  var updateAPIToken: (String?) -> Void
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
