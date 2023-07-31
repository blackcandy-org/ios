import Foundation
import Dependencies

struct JSONDataClient {
  var currentUser: () -> User?
  var updateCurrentUser: (User) -> Void
  var deleteCurrentUser: () -> Void
}

extension JSONDataClient: TestDependencyKey {
  static let testValue = Self(
    currentUser: unimplemented("\(Self.self).currentUser"),
    updateCurrentUser: { _ in },
    deleteCurrentUser: {}
  )
}

extension DependencyValues {
  var jsonDataClient: JSONDataClient {
    get { self[JSONDataClient.self] }
    set { self[JSONDataClient.self] = newValue }
  }
}
