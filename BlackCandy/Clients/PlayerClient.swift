import Foundation
import AVFoundation
import ComposableArchitecture
import Combine

struct PlayerClient {
  private static let player = AVPlayer()
  private static var apiToken: String?

  var updateAPIToken: (String?) -> Void
  var hasCurrentItem: () -> Bool
  var playOn: (Song) -> Void
  var play: () -> Void
  var pause: () -> Void
  var getCurrentTime: () -> Effect<Double, Never>
}

extension PlayerClient {
  static let live = Self(
    updateAPIToken: { token in
      apiToken = token
    },

    hasCurrentItem: {
      player.currentItem != nil
    },

    playOn: { song in
      guard let apiToken = apiToken else { return }

      let asset = AVURLAsset(url: song.url, options: ["AVURLAssetHTTPHeaderFieldsKey": ["Authorization": "Token \(apiToken)"]])
      let playerItem = AVPlayerItem(asset: asset)

      player.replaceCurrentItem(with: playerItem)
      player.play()
    },

    play: {
      player.play()
    },

    pause: {
      player.pause()
    },

    getCurrentTime: {
      .run { subscriber in
        var observer: Any?

        let cancellable = AnyCancellable {
          player.removeTimeObserver(observer!)
        }

        observer = player.addPeriodicTimeObserver(forInterval: .init(seconds: 1, preferredTimescale: 1), queue: .main, using: { _ in
          subscriber.send(player.currentItem?.currentTime().seconds ?? 0)
        })

        return cancellable
      }
    }
  )
}
