import UIKit

class TabBarViewController: UITabBarController, UITabBarControllerDelegate {
  let tabItems: [TabItem] = [.home, .library]

  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self
    tabBar.isHidden = true
    viewControllers = tabItems.map { tabItem in
      let viewController = tabItem.viewController
      viewController.tabBarItem = .init(title: tabItem.title, image: tabItem.icon, tag: tabItem.tagIndex)

      return viewController
    }
  }

  func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
    guard let primaryViewController = splitViewController?.viewController(for: .primary) as? SideBarViewController else { return }

    let selectedTagIndex = viewController.tabBarItem.tag
    guard let selectedTabItem = tabItems.first(where: { $0.tagIndex == selectedTagIndex}) else { return }

    primaryViewController.selectTabItem(selectedTabItem)
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
      return TurboNavigationController(path: "http://localhost:3000/")
    case .library:
      return TurboNavigationController(path: "http://localhost:3000/library")
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
