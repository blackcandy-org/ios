import Foundation
import AVFoundation

class Player: Equatable {
  let audioPlayer: AVPlayer
  let playlist: Playlist

  init(songs: [Song]) {
    self.audioPlayer = AVPlayer()
    self.playlist = Playlist(songs: songs)
  }

  func play() {
  }

  static func == (lhs: Player, rhs: Player) -> Bool {
    lhs.playlist == rhs.playlist
  }
}
