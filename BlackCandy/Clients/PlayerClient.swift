import Foundation
import AVFoundation

struct PlayerClient {
  private static let player = AVPlayer()
  private static var apiToken: String?

  var updateAPIToken: (String?) -> Void
  var hasCurrentItem: () -> Bool
  var playOn: (Song) -> Void
  var play: () -> Void
  var pause: () -> Void
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
    }
  )
}
