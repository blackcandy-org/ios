import Turbo
import UIKit

class TurboVisitableViewController: VisitableViewController, UISearchBarDelegate {
  var properties: PathProperties!

  convenience init(_ url: URL, properties: PathProperties) {
    self.init(url: url)
    self.properties = properties
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground

    if properties["has_search_bar"] as? Bool ?? false {
      setSearchBar()
    }

    if let navButtonProperty = properties["nav_button"] as? [String: String] {
      setNavButton(navButtonProperty)
    }
  }

  func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    guard let searchText = searchBar.searchTextField.text, !searchText.isEmpty else { return }

    visitableView.webView?.evaluateJavaScript("App.nativeBridge.search('\(searchText)')")
  }

  private func setSearchBar() {
    let searchController = UISearchController(searchResultsController: nil)
    searchController.searchBar.delegate = self

    navigationItem.searchController = searchController
    navigationItem.hidesSearchBarWhenScrolling = false
  }

  private func setNavButton(_ property: [String: String]) {
    let button = UIBarButtonItem()

    button.title = property["title"]

    button.primaryAction = .init(handler: { [weak self] _ in
      guard
        let path = property["path"],
        let viewController = self?.navigationController as? TurboNavigationController else {
        return
      }

      viewController.route(path)
    })

    if let iconName = property["icon"] {
      button.image = .init(systemName: iconName)
    }

    navigationItem.rightBarButtonItem = button
  }
}
