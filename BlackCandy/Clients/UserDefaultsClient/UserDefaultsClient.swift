import Foundation
import Dependencies

struct UserDefaultsClient {
  var serverAddress: () -> URL?
  var updateServerAddress: (URL?) -> Void
}

extension UserDefaultsClient: TestDependencyKey {
  static let testValue = Self(
    serverAddress: {
      URL(string: "http://localhost:3000")
    },

    updateServerAddress: { _ in }
  )
}

extension DependencyValues {
  var userDefaultsClient: UserDefaultsClient {
    get { self[UserDefaultsClient.self] }
    set { self[UserDefaultsClient.self] = newValue }
  }
}
