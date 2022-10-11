import Foundation

struct Playlist: Equatable {
  var isShuffled = false
  var orderedSongs: [Song] = []
  private var shuffledSongs: [Song] = []

  var songs: [Song] {
    isShuffled ? shuffledSongs : orderedSongs
  }

  func index(of song: Song) -> Int? {
    if isShuffled {
      return shuffledSongs.firstIndex(of: song)
    } else {
      return orderedSongs.firstIndex(of: song)
    }
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
