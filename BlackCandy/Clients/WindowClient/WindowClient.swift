import Foundation
import Dependencies
import UIKit

struct WindowClient {
  var changeRootViewController: (UIViewController) -> Void
}

extension WindowClient: TestDependencyKey {
  static let testValue = Self(
    changeRootViewController: { _ in }
  )
}

extension DependencyValues {
  var windowClient: WindowClient {
    get { self[WindowClient.self] }
    set { self[WindowClient.self] = newValue }
  }
}
