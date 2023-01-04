import UIKit
import SwiftUI
import Turbo
import ComposableArchitecture

struct TurboView: UIViewControllerRepresentable {
  let path: String
  var session: Session?
  var hasSearchBar = false
  var hasNavigationBar = true

  func makeUIViewController(context: Context) -> UINavigationController {
    let navigationController = TurboNavigationController(path: path, session: session, hasSearchBar: hasSearchBar)
    navigationController.isNavigationBarHidden = !hasNavigationBar

    return navigationController
  }

  func updateUIViewController(_ navigationController: UINavigationController, context: Context) {
  }

  static func dismantleUIViewController(_ uiViewController: UINavigationController, coordinator: Coordinator) {
    uiViewController.popViewController(animated: false)
    uiViewController.viewControllers = []
  }
}
