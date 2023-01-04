import UIKit
import ComposableArchitecture
import SwiftUI

class TabBarViewController: UITabBarController, UITabBarControllerDelegate {
  let playerViewController: PlayerViewController
  let tabItems: [TabItem] = [.home, .library]

  init(store: StoreOf<PlayerReducer>) {
    self.playerViewController = PlayerViewController(store: store)
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self
    tabBar.isHidden = true
    viewControllers = tabItems.map { tabItem in
      let viewController = tabItem.viewController
      viewController.tabBarItem = .init(title: tabItem.title, image: tabItem.icon, tag: tabItem.tagIndex)

      return viewController
    }

    let notificationCenter = NotificationCenter.default

    notificationCenter.addObserver(
      self,
      selector: #selector(selectedTabDidChanged(_:)),
      name: .selectedTabDidChange,
      object: nil
    )

    notificationCenter.addObserver(
      self,
      selector: #selector(splitViewDidExpand(_:)),
      name: .splitViewDidExpand,
      object: nil
    )

    notificationCenter.addObserver(
      self,
      selector: #selector(splitViewDidCollapse(_:)),
      name: .splitViewDidCollapse,
      object: nil
    )
  }

  func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
    let selectedTagIndex = viewController.tabBarItem.tag
    guard let selectedTabItem = tabItems.first(where: { $0.tagIndex == selectedTagIndex}) else { return }

    NotificationCenter.default.post(
      name: .selectedTabDidChange,
      object: self,
      userInfo: [NotificationKeys.selectedTab: selectedTabItem]
    )
  }

  @objc private func selectedTabDidChanged(_ notification: Notification) {
    guard let userInfo = notification.userInfo,
      let selectedTab = userInfo[NotificationKeys.selectedTab] as? TabItem else { return }

    selectedIndex = selectedTab.tagIndex
  }

  @objc private func splitViewDidExpand(_ notification: Notification) {
    tabBar.isHidden = true
    dismissPopupBar(animated: false)
  }

  @objc private func splitViewDidCollapse(_ notification: Notification) {
    tabBar.isHidden = false
    presentPopupBar(withContentViewController: playerViewController, animated: false)
  }
}

enum TabItem: String {
  case home
  case library

  var title: String {
    rawValue.capitalized
  }

  var icon: UIImage? {
    switch self {
    case .home:
      return .init(systemName: "house")
    case .library:
      return .init(systemName: "square.stack")
    }
  }

  var viewController: UIViewController {
    switch self {
    case .home:
      return TurboNavigationController(path: "/")
    case .library:
      return TurboNavigationController(path: "/library", hasSearchBar: true)
    }
  }

  var tagIndex: Int {
    switch self {
    case .home:
      return 0
    case .library:
      return 1
    }
  }
}
