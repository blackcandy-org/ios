import Foundation

struct Playlist: Equatable {
  var isShuffled = false
  var orderedSongs: [Song] = []
  private var shuffledSongs: [Song] = []

  var songs: [Song] {
    isShuffled ? shuffledSongs : orderedSongs
  }

  func index(of song: Song) -> Int? {
    songs.firstIndex(of: song)
  }

  func index(by songId: Int) -> Int? {
    songs.firstIndex(where: { $0.id == songId })
  }

  mutating func update(songs: [Song]) {
    orderedSongs = songs
    shuffledSongs = songs.shuffled()
  }

  mutating func remove(songs: [Song]) {
    orderedSongs.removeAll(where: { songs.contains($0) })
    shuffledSongs.removeAll(where: { songs.contains($0) })
  }

  mutating func insert(_ song: Song, at index: Int) {
    orderedSongs.insert(song, at: index)
    shuffledSongs.insert(song, at: index)
  }
}
