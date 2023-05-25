import Foundation
import Dependencies

struct KeychainClient {
  var apiToken: () -> String?
  var updateAPIToken: (String) -> Void
  var deleteAPIToken: () -> Void
}

extension KeychainClient: TestDependencyKey {
  static let testValue = Self(
    apiToken: {
      "test_token"
    },
    updateAPIToken: { _ in },
    deleteAPIToken: {}
  )
}

extension DependencyValues {
  var keychainClient: KeychainClient {
    get { self[KeychainClient.self] }
    set { self[KeychainClient.self] = newValue }
  }
}
