import Foundation
import MediaPlayer
import UIKit
import Alamofire

struct NowPlayingClient {
  var updateInfo: (Song) -> Void
  var updatePlaybackInfo: (Float, Float) -> Void

  static func updateAlbumImage(url: URL, completionHandler: (() -> Void)? = nil) {
    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()

    AF.download(url).response { response in
      guard
        response.error == nil,
        let imagePath = response.fileURL?.path,
        let image = UIImage(contentsOfFile: imagePath) else { return }

      nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { _ in
        return image
      })

      MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

      completionHandler?()
    }
  }
}

extension NowPlayingClient {
  static let live = Self(
    updateInfo: { song in
      var nowPlayingInfo = [String: Any]()

      nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
      nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = 0
      nowPlayingInfo[MPMediaItemPropertyTitle] = song.name
      nowPlayingInfo[MPMediaItemPropertyArtist] = song.artistName
      nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = song.albumName
      nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = song.duration

      MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

      updateAlbumImage(url: song.albumImageUrl.large)
    },

    updatePlaybackInfo: { position, rate in
      var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()

      nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = position
      nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = rate
      nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0

      MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
  )
}
