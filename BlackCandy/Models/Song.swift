import Foundation

struct Song: Codable, Equatable, Identifiable {
  let id: Int
  let name: String
  let duration: Double
  let url: URL
  let albumName: String
  let artistName: String
  let format: String
  let albumImageUrl: ImageURL

  var isFavorited: Bool
}

extension Song {
  struct ImageURL: Codable, Equatable {
    let small: URL
    let medium: URL
    let large: URL
  }
}
