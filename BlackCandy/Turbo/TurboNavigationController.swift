import UIKit
import SwiftUI
import ComposableArchitecture
import Turbo

class TurboNavigationController: UINavigationController, SessionDelegate {
  let hasSearchBar: Bool
  let url: URL
  let viewStore = ViewStore(AppStore.shared, removeDuplicates: ==)

  private let sharedSession: Session?

  init(path: String, session: Session? = nil, hasSearchBar: Bool = false) {
    self.sharedSession = session
    self.hasSearchBar = hasSearchBar
    self.url = viewStore.serverAddress!.appendingPathComponent(path)

    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  lazy var viewSession: Session = {
    let session = self.sharedSession ?? TurboSession.create()
    session.delegate = self

    return session
  }()

  private lazy var modalSession: Session = {
    let session = TurboSession.create()
    session.delegate = self

    return session
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    let visitableViewController = TurboVisitableViewController(url: url)

    visitableViewController.hasSearchBar = hasSearchBar

    if url.path == "/" {
      visitableViewController.navigationItem.rightBarButtonItem = .init(
        image: .init(systemName: "person.circle"),
        style: .done,
        target: self,
        action: #selector(self.showAccount)
      )
    }

    viewControllers = [visitableViewController]

    viewSession.visit(visitableViewController)
  }

  func session(_ session: Turbo.Session, didProposeVisit proposal: Turbo.VisitProposal) {
    let viewController = TurboVisitableViewController(url: proposal.url)
    let presentation = proposal.properties["presentation"] as? String
    let visitOptions = proposal.options

    // Dismiss any modals when receiving a new navigation
    if presentedViewController != nil {
      dismiss(animated: true)
    }

    if presentation == "modal" {
      let modalViewController = UINavigationController(rootViewController: viewController)

      present(modalViewController, animated: true)
      modalSession.visit(viewController, options: visitOptions)
      return
    }

    if session.activeVisitable?.visitableURL == proposal.url || visitOptions.action == .replace {
      let viewControllers = Array(viewControllers.dropLast()) + [viewController]

      setViewControllers(viewControllers, animated: false)
      session.visit(viewController, options: visitOptions)
      return
    }

    pushViewController(viewController, animated: true)
    session.visit(viewController, options: visitOptions)
  }

  func sessionWebViewProcessDidTerminate(_ session: Turbo.Session) {
    session.reload()
  }

  func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
    if let turboError = error as? TurboError {
      switch turboError {
      case .http(let statusCode):
        if statusCode == 401 {
          viewStore.send(.logout)
        }
      case .networkFailure, .timeoutFailure:
        return
      case .contentTypeMismatch:
        return
      case .pageLoadFailure:
        return
      }
    } else {
      NSLog("didFailRequestForVisitable: \(error)")
    }
  }

  @objc func showAccount() {
    present(UIHostingController(rootView: AccountView(store: AppStore.shared)), animated: true)
  }
}
