import XCTest

extension XCTestCase {
  func fixtureData<T: Decodable>(_ bundleFile: String) throws -> T {
    let bundle = Bundle(for: type(of: self))

    guard let fileUrl = bundle.url(forResource: bundleFile, withExtension: "json") else {
      fatalError("Resource not found: \(bundleFile)")
    }

    let data = try Data(contentsOf: fileUrl)
    let decoder = JSONDecoder()

    decoder.keyDecodingStrategy = .convertFromSnakeCase

    return try decoder.decode(T.self, from: data)
  }

  func decodeJSON<T: Decodable>(from json: String) throws -> T {
    let data = json.data(using: .utf8)!
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    return try decoder.decode(T.self, from: data)
  }
}
