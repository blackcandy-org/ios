import SwiftUI

struct SidebarView: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> UISplitViewController {
    let splitViewController = UIViewControllerType(style: .doubleColumn)
    splitViewController.setViewController(SidebarNavigationController(), for: .primary)
    splitViewController.setViewController(TurboNavigationController(path: "/"), for: .secondary)

    return splitViewController
  }

  func updateUIViewController(_ uiViewController: UISplitViewController, context: Context) {
  }
}
