import Foundation
import Dependencies

struct JSONDataClient {
  var currentUser: () -> User?
  var updateCurrentUser: (User, (() -> Void)?) -> Void
  var deleteCurrentUser: () -> Void
}

extension JSONDataClient: TestDependencyKey {
}

extension DependencyValues {
  var jsonDataClient: JSONDataClient {
    get { self[JSONDataClient.self] }
    set { self[JSONDataClient.self] = newValue }
  }
}
