import Foundation
import Dependencies

struct FlashMessageClient {
  var showMessage: (String.LocalizationValue) -> Void
}

extension FlashMessageClient: TestDependencyKey {
  static let testValue = Self(
    showMessage: { _ in }
  )
}

extension DependencyValues {
  var flashMessageClient: FlashMessageClient {
    get { self[FlashMessageClient.self] }
    set { self[FlashMessageClient.self] = newValue }
  }
}
