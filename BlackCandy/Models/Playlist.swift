import Foundation

struct Playlist: Equatable {
  var isShuffled = false
  private var shuffledSongs: [Song] = []
  private var orderedSongs: [Song] = []

  var songs: [Song] {
    get {
      isShuffled ? shuffledSongs : orderedSongs
    }

    set {
      orderedSongs = newValue
      shuffledSongs = newValue.shuffled()
    }
  }
}
