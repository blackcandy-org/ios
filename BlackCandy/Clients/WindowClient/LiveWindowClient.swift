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
        let store = AppStore.shared

        changeRootViewController(UIHostingController(
          rootView: LoginView(store: store.scope(state: \.login, action: AppReducer.Action.login))
            .alert(store: store.scope(state: \.$alert, action: { .alert($0) }))
        ))
      }
    )
  }

  static let liveValue = live()
}
