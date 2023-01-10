import Foundation

struct SystemInfo: Codable, Equatable {
  static let supportedMinimumMajorVersion = 3

  let version: Version
  var serverAddress: URL?

  var isSupported: Bool {
    version.major >= Self.supportedMinimumMajorVersion
  }
}

extension SystemInfo {
  struct Version: Codable, Equatable {
    let major: Int
    let minor: Int
    let patch: Int
    let pre: String
  }
}
