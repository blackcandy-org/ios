import Foundation
import Dependencies
import UIKit

struct WindowClient {
  var switchToMainView: () -> Void
  var switchToLoginView: () -> Void
}

extension WindowClient: TestDependencyKey {
  static let testValue = Self(
    switchToMainView: {},
    switchToLoginView: {}
  )
}

extension DependencyValues {
  var windowClient: WindowClient {
    get { self[WindowClient.self] }
    set { self[WindowClient.self] = newValue }
  }
}
