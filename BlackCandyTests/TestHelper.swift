import XCTest

@testable import BlackCandy

extension XCTestCase {
  func songs() throws -> [Song] {
    try fixtureData("songs")
  }

  func songs(id: Int) throws -> Song {
    try songs().first(where: { $0.id == id })!
  }

  func users() throws -> [User] {
    try fixtureData("users")
  }

  func users(id: Int) throws -> User {
    try users().first(where: { $0.id == id })!
  }

  func decodeJSON<T: Decodable>(from json: String) throws -> T {
    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    return try decoder.decode(T.self, from: data)
  }

  private func fixtureData<T: Decodable>(_ bundleFile: String) throws -> T {
    let bundle = Bundle(for: type(of: self))

    guard let fileUrl = bundle.url(forResource: bundleFile, withExtension: "json") else {
      fatalError("Resource not found: \(bundleFile)")
    }

    let data = try Data(contentsOf: fileUrl)
    let decoder = JSONDecoder()

    decoder.keyDecodingStrategy = .convertFromSnakeCase

    return try decoder.decode(T.self, from: data)
  }
}
