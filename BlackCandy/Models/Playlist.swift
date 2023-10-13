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

  func find(bySongId id: Int) -> Song? {
    songs.first(where: { $0.id == id })
  }

  func find(byIndex index: Int) -> Song? {
    let songsCount = songs.count

    if index >= songsCount {
      return songs.first
    } else if index < 0 {
      return songs.last
    } else {
      return songs[index]
    }
  }

  mutating func update(songs: [Song]) {
    orderedSongs = songs
    shuffledSongs = songs.shuffled()
  }

  mutating func update(song: Song) {
    if let index = orderedSongs.firstIndex(where: { $0.id == song.id }) {
      orderedSongs[index] = song
    }

    if let index = shuffledSongs.firstIndex(where: { $0.id == song.id }) {
      shuffledSongs[index] = song
    }
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
