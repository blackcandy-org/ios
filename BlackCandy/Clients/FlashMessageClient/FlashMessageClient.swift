import Foundation
import Dependencies

struct FlashMessageClient {
  var showLocalizedMessage: (String.LocalizationValue) -> Void
  var showMessage: (String) -> Void
}

extension FlashMessageClient: TestDependencyKey {
  static let testValue = Self(
    showLocalizedMessage: { _ in },
    showMessage: { _ in }
  )
}

extension DependencyValues {
  var flashMessageClient: FlashMessageClient {
    get { self[FlashMessageClient.self] }
    set { self[FlashMessageClient.self] = newValue }
  }
}
