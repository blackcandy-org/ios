import Foundation
import SwiftUI
import UIKit
import Dependencies

extension WindowClient: DependencyKey {
  static func live() -> Self {
    func changeRootViewController(_ viewController: UIViewController) {
      let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
      sceneDelegate?.window?.rootViewController = viewController
    }

    return Self(
      switchToMainView: {
        changeRootViewController(MainViewController(store: AppStore.shared))
      },

      switchToLoginView: {
        changeRootViewController(UIHostingController(rootView: LoginView(store: AppStore.shared)))
      }
    )
  }

  static let liveValue = live()
}
