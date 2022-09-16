import Foundation

struct Song: Codable, Equatable, Identifiable {
  let id: Int
  let name: String
  let duration: Double
  let url: URL
  let albumName: String
  let artistName: String
  let isFavorited: Bool
  let format: String
  let albumImageUrl: ImageURL
}

extension Song {
  struct ImageURL: Codable, Equatable {
    let small: URL
    let medium: URL
    let large: URL
  }
}
