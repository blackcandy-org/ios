import Foundation
import UIKit
import Dependencies

extension WindowClient: DependencyKey {
  static let liveValue = Self(
    changeRootViewController: { viewController in
      let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
      sceneDelegate?.window?.rootViewController = viewController
    }
  )
}
