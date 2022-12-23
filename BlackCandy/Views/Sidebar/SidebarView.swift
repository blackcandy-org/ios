import SwiftUI

struct SidebarView<Sidebar, Detail>: UIViewControllerRepresentable where Sidebar: View, Detail: View {
  let sidebar: () -> Sidebar
  let detail: () -> Detail

  func makeUIViewController(context: Context) -> UISplitViewController {
    let splitViewController = UIViewControllerType(style: .doubleColumn)

    splitViewController.preferredDisplayMode = .oneBesideSecondary
    splitViewController.presentsWithGesture = false
    splitViewController.setViewController(UIHostingController(rootView: sidebar()), for: .primary)
    splitViewController.setViewController(UIHostingController(rootView: detail()), for: .secondary)

    return splitViewController
  }

  func updateUIViewController(_ uiViewController: UISplitViewController, context: Context) {
  }
}
