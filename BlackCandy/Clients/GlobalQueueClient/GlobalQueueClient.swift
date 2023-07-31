import Foundation
import Dependencies

struct GlobalQueueClient {
  var async: (DispatchQoS.QoSClass, @escaping () -> Void) -> Void
}

extension GlobalQueueClient: TestDependencyKey {
  static let testValue = Self(
    async: { _, work in work() }
  )
}

extension DependencyValues {
  var globalQueueClient: GlobalQueueClient {
    get { self[GlobalQueueClient.self] }
    set { self[GlobalQueueClient.self] = newValue }
  }
}
