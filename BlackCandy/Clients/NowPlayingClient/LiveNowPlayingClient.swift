import Foundation
import Dependencies
import MediaPlayer
import UIKit
import Alamofire

extension NowPlayingClient: DependencyKey {
  static func live() -> Self {
    func updateAlbumImage(url: URL) async {
      var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()

      let fileURL = try? await AF.download(url).serializingDownloadedFileURL().value

      guard
        let imagePath = fileURL?.path,
        let image = UIImage(contentsOfFile: imagePath) else { return }

      nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { _ in
        return image
      })

      MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    return Self(
      updateInfo: { song in
        var nowPlayingInfo = [String: Any]()

        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = 0
        nowPlayingInfo[MPMediaItemPropertyTitle] = song.name
        nowPlayingInfo[MPMediaItemPropertyArtist] = song.artistName
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = song.albumName
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = song.duration

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

        await updateAlbumImage(url: song.albumImageUrl.large)
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

  static let liveValue = live()
}
