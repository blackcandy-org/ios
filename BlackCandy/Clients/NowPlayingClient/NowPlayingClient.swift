import Foundation
import Dependencies

struct NowPlayingClient {
  var updateInfo: (Song) -> Void
  var updatePlaybackInfo: (Float, Float) -> Void
}

extension NowPlayingClient: TestDependencyKey {
}

extension DependencyValues {
  var nowPlayingClient: NowPlayingClient {
    get { self[NowPlayingClient.self] }
    set { self[NowPlayingClient.self] = newValue }
  }
}
