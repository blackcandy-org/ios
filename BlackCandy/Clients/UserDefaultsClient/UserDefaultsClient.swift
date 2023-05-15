import Foundation
import Dependencies

struct UserDefaultsClient {
  var serverAddress: () -> URL?
  var updateServerAddress: (URL?) -> Void
}

extension UserDefaultsClient: TestDependencyKey {
}

extension DependencyValues {
  var userDefaultsClient: UserDefaultsClient {
    get { self[UserDefaultsClient.self] }
    set { self[UserDefaultsClient.self] = newValue }
  }
}
