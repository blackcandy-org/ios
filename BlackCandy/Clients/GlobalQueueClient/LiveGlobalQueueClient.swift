import Foundation
import Dependencies

extension GlobalQueueClient: DependencyKey {
  static let liveValue = Self(
    async: { qos, work in
      DispatchQueue.global(qos: qos).async {
        work()
      }
    }
  )
}
