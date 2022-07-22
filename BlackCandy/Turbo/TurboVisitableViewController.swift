import Turbo
import UIKit

class TurboVisitableViewController: VisitableViewController, UITextFieldDelegate {
  var hasSearchBar = false

  override func viewDidLoad() {
    super.viewDidLoad()

    if hasSearchBar {
      let searchController = UISearchController(searchResultsController: nil)

      searchController.searchBar.searchTextField.delegate = self
      navigationItem.searchController = searchController
    }
  }

  func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
    guard reason == .committed && !(textField.text ?? "").isEmpty else { return }

    let queryUrl = "/search?query=\(textField.text!)"
    let searchScript = "window.Turbo.visit('\(queryUrl)');"

    visitableView.webView?.evaluateJavaScript(searchScript)
  }
}
