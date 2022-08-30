import Foundation

struct User: Codable, Equatable {
  let id: Int
  let email: String
  let isAdmin: Bool
}
