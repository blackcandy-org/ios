import Foundation
import MediaPlayer
import UIKit
import Alamofire

struct NowPlayingClient {
  var updateInfo: (Song) -> Void
  var updatePlaybackPosition: (TimeInterval) -> Void

  private static func updateAlbumImage(url: URL) {
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

    updatePlaybackPosition: { time in
      var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
      nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time

      MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
  )
}
