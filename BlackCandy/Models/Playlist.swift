import Foundation

struct Playlist: Equatable {
  var isShuffled = false
  private var shuffledSongs: [Song] = []
  private var orderedSongs: [Song] = []

  var songs: [Song] {
    isShuffled ? shuffledSongs : orderedSongs
  }

  mutating func update(songs: [Song]) {
    orderedSongs = songs
    shuffledSongs = songs.shuffled()
  }

  mutating func remove(songs: [Song]) {
    orderedSongs.removeAll(where: { songs.contains($0) })
    shuffledSongs.removeAll(where: { songs.contains($0) })
  }
}
