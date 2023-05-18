import Foundation
import Dependencies

struct JSONDataClient {
  var currentUser: () -> User?
  var updateCurrentUser: (User, (() -> Void)?) -> Void
  var deleteCurrentUser: () -> Void
}

extension JSONDataClient: TestDependencyKey {
  static let testValue = Self(
    currentUser: {
      User(id: 1, email: "test@test.com", isAdmin: true)
    },
    updateCurrentUser: { _, _ in },
    deleteCurrentUser: {}
  )
}

extension DependencyValues {
  var jsonDataClient: JSONDataClient {
    get { self[JSONDataClient.self] }
    set { self[JSONDataClient.self] = newValue }
  }
}
