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

    visitableView.webView?.evaluateJavaScript("window.NativeBridge.search('\(searchText)')")
  }

  override func visitableDidRender() {
    visitableView.webView?.evaluateJavaScript("window.NativeBridge.nativeTitle") { (title, error) -> Void in
      guard error == nil && title != nil else { return }
      self.title = title as? String
    }
  }
}
