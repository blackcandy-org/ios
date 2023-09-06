import Foundation
import SwiftUI
import UIKit
import Dependencies

extension WindowClient: DependencyKey {
  static func live() -> Self {
    return Self(
      changeRootViewController: { viewController in
        let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
        sceneDelegate?.window?.rootViewController = viewController
      }
    )
  }

  static let liveValue = live()
}
