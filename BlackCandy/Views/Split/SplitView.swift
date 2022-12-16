import SwiftUI

struct SplitView: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> UISplitViewController {
    let splitViewController = UIViewControllerType(style: .doubleColumn)
    splitViewController.setViewController(SplitNavigationViewController(), for: .primary)
    splitViewController.setViewController(UIHostingController(rootView: TurboView(path: "/")), for: .secondary)

    return splitViewController
  }

  func updateUIViewController(_ uiViewController: UISplitViewController, context: Context) {
  }
}
