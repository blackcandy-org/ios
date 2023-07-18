import Foundation
import Dependencies

struct NowPlayingClient {
  var updateInfo: (Song) async -> Void
  var updatePlaybackInfo: (Float, Float) -> Void
}

extension NowPlayingClient: TestDependencyKey {
  static let testValue = Self(
    updateInfo: { _ in },
    updatePlaybackInfo: { _, _ in }
  )
}

extension DependencyValues {
  var nowPlayingClient: NowPlayingClient {
    get { self[NowPlayingClient.self] }
    set { self[NowPlayingClient.self] = newValue }
  }
}
