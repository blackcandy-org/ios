import Foundation
import Dependencies
import AVFoundation

extension PlayerClient: DependencyKey {
  static func live(player: AVPlayer) -> Self {
    @Dependency(\.keychainClient) var keychainClient

    return Self(
      hasCurrentItem: {
        player.currentItem != nil
      },

      playOn: { songUrl in
        guard let apiToken = keychainClient.apiToken() else { return }

        let asset = AVURLAsset(url: songUrl, options: [
          "AVURLAssetHTTPHeaderFieldsKey": [
            "Authorization": "Token \(apiToken)",
            "User-Agent": "Turbo Native iOS"
          ]
        ])

        let playerItem = AVPlayerItem(asset: asset)

        player.pause()
        player.replaceCurrentItem(with: playerItem)
        player.play()
      },

      play: {
        player.play()
      },

      pause: {
        player.pause()
      },

      replay: {
        player.seek(to: CMTime.zero)
        player.play()
      },

      seek: { time in
        player.seek(to: time)
      },

      stop: {
        player.seek(to: CMTime.zero)
        player.pause()
      },

      getCurrentTime: {
        AsyncStream { continuation in
          let observer = player.addPeriodicTimeObserver(forInterval: .init(seconds: 1, preferredTimescale: 1), queue: .global(qos: .background), using: { _ in
            continuation.yield(player.currentTime().seconds )
          })

          continuation.onTermination = { @Sendable _ in
            player.removeTimeObserver(observer)
          }
        }
      },

      getStatus: {
        AsyncStream { continuation in
          let timeControlStatusObserver = player.observe(\AVPlayer.timeControlStatus, changeHandler: { (player, _) in
            switch player.timeControlStatus {
            case .paused:
              continuation.yield(.pause)
            case .waitingToPlayAtSpecifiedRate:
              continuation.yield(.loading)
            case .playing:
              continuation.yield(.playing)
            @unknown default:
              continuation.yield(.pause)
            }
          })

          let playToEndObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main, using: { _ in
            continuation.yield(.end)
          })

          continuation.onTermination = { @Sendable _ in
            timeControlStatusObserver.invalidate()
            NotificationCenter.default.removeObserver(playToEndObserver)
          }
        }
      },

      getPlaybackRate: {
        player.rate
      }
    )
  }

  static var liveValue = live(player: AVPlayer())
}
