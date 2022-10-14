import Turbo
import UIKit

class TurboVisitableViewController: VisitableViewController, UISearchBarDelegate {
  var hasSearchBar = false

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .clear

    guard hasSearchBar else { return }

    let searchController = UISearchController(searchResultsController: nil)
    searchController.searchBar.delegate = self

    navigationItem.searchController = searchController
    navigationItem.hidesSearchBarWhenScrolling = false
  }

  func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    guard let searchText = searchBar.searchTextField.text, !searchText.isEmpty else { return }

    let queryUrl = "/search?query=\(searchText)"
    let searchScript = "window.Turbo.visit('\(queryUrl)');"

    visitableView.webView?.evaluateJavaScript(searchScript)
  }

  override func visitableDidRender() {
    let titleScript = "document.querySelector('meta[data-native-title]').dataset.nativeTitle"

    visitableView.webView?.evaluateJavaScript(titleScript) { (title, error) -> Void in
      guard error == nil && title != nil else { return }
      self.title = title as? String
    }
  }
}
