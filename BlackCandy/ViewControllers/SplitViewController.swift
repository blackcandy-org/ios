import UIKit

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {
  init() {
    super.init(style: .doubleColumn)

    let tabBarViewController = TabBarViewController()

    preferredDisplayMode = .oneBesideSecondary
    preferredSplitBehavior = .tile
    presentsWithGesture = false
    delegate = self

    setViewController(SideBarViewController(), for: .primary)
    setViewController(tabBarViewController, for: .secondary)
    setViewController(tabBarViewController, for: .compact)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func splitViewControllerDidExpand(_ svc: UISplitViewController) {
    guard let secondaryViewController = svc.viewController(for: .secondary) as? UITabBarController else { return }
    secondaryViewController.tabBar.isHidden = true
  }

  func splitViewControllerDidCollapse(_ svc: UISplitViewController) {
    guard let secondaryViewController = svc.viewController(for: .compact) as? UITabBarController else { return }
    secondaryViewController.tabBar.isHidden = false
  }
}
