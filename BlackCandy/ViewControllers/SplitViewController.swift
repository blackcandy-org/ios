import UIKit
import ComposableArchitecture
import SwiftUI

struct SplitView: UIViewControllerRepresentable {
  let store: StoreOf<PlayerReducer>

  func makeUIViewController(context: Context) -> SplitViewController {
    return SplitViewController(store: store)
  }

  func updateUIViewController(_ uiViewController: SplitViewController, context: Context) {
  }
}

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {
  init(store: StoreOf<PlayerReducer>) {
    super.init(style: .doubleColumn)

    let tabBarViewController = TabBarViewController(store: store)
    let sidebarViewController = UIHostingController(rootView: SideBarView(store: store))

    preferredDisplayMode = .oneBesideSecondary
    preferredSplitBehavior = .tile
    presentsWithGesture = false
    delegate = self

    setViewController(sidebarViewController, for: .primary)
    setViewController(tabBarViewController, for: .secondary)
    setViewController(tabBarViewController, for: .compact)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func splitViewControllerDidExpand(_ svc: UISplitViewController) {
    NotificationCenter.default.post(
      name: .splitViewDidExpand,
      object: self
    )
  }

  func splitViewControllerDidCollapse(_ svc: UISplitViewController) {
    NotificationCenter.default.post(
      name: .splitViewDidCollapse,
      object: self
    )
  }
}
