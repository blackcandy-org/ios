import Foundation
import Dependencies

struct KeychainClient {
  var apiToken: () -> String?
  var updateAPIToken: (String) -> Void
  var deleteAPIToken: () -> Void
}

extension KeychainClient: TestDependencyKey {
}

extension DependencyValues {
  var keychainClient: KeychainClient {
    get { self[KeychainClient.self] }
    set { self[KeychainClient.self] = newValue }
  }
}
