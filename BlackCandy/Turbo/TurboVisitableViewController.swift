import Turbo
import UIKit

class TurboVisitableViewController: VisitableViewController, UISearchBarDelegate {
  var hasSearchBar = false

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .systemBackground

    if hasSearchBar {
      let searchController = UISearchController(searchResultsController: nil)
      searchController.searchBar.delegate = self

      navigationItem.searchController = searchController
      navigationItem.hidesSearchBarWhenScrolling = false
    }
  }

  func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    guard let searchText = searchBar.searchTextField.text, !searchText.isEmpty else { return }

    visitableView.webView?.evaluateJavaScript("App.nativeBridge.search('\(searchText)')")
  }
}
