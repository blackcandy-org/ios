import UIKit
import SwiftUI
import ComposableArchitecture
import Turbo

class TurboNavigationController: UINavigationController, SessionDelegate {
  @Dependency(\.userDefaultsClient) var userDefaultsClient

  let initPath: String
  let store: StoreOf<AppReducer>
  let viewStore: ViewStoreOf<AppReducer>

  init(_ initPath: String, store: StoreOf<AppReducer> = AppStore.shared) {
    self.initPath = initPath
    self.store = store
    self.viewStore = ViewStore(store, removeDuplicates: ==)

    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  lazy var session: Session = {
    let session = TurboSession.create(store: store)
    session.delegate = self

    return session
  }()

  private lazy var modalSession: Session = {
    let session = TurboSession.create(store: store)
    session.delegate = self

    return session
  }()

  func route(_ path: String) {
    let url = userDefaultsClient.serverAddress()!.appendingPathComponent(path)
    let options = VisitOptions(action: .advance, response: nil)
    let properties = session.pathConfiguration?.properties(for: url) ?? PathProperties()
    let proposal = VisitProposal(url: url, options: options, properties: properties)

    route(proposal: proposal)
  }

  func route(proposal: VisitProposal) {
    let presentation = proposal.properties["presentation"] as? String
    let visitOptions = proposal.options
    let viewController = makeViewController(for: proposal.url, properties: proposal.properties)

    // Dismiss any modals when receiving a new navigation
    if presentedViewController != nil {
      dismiss(animated: true)
    }

    if presentation == "modal" {
      let modalViewController = UINavigationController(rootViewController: viewController)

      present(modalViewController, animated: true)
      visit(viewController: viewController, with: visitOptions, modal: true)
      return
    }

    if session.activeVisitable?.visitableURL == proposal.url || visitOptions.action == .replace {
      let viewControllers = Array(viewControllers.dropLast()) + [viewController]

      setViewControllers(viewControllers, animated: false)
      visit(viewController: viewController, with: visitOptions)
      return
    }

    pushViewController(viewController, animated: true)
    visit(viewController: viewController, with: visitOptions)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let navigationBarAppearance = UINavigationBarAppearance()
    navigationBarAppearance.configureWithDefaultBackground()

    navigationBar.standardAppearance = navigationBarAppearance
    navigationBar.scrollEdgeAppearance = navigationBarAppearance

    route(initPath)
  }

  func session(_ session: Turbo.Session, didProposeVisit proposal: Turbo.VisitProposal) {
    route(proposal: proposal)
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

  private func makeViewController(for url: URL, properties: PathProperties) -> UIViewController {
    let defaultViewController = TurboVisitableViewController(url, properties: properties)

    if let rootView = properties["root_view"] as? String {
      switch rootView {
      case "account":
        return UIHostingController(
          rootView: AccountView(
            store: store,
            navItemTapped: { path in
              self.route(path)
            }
          )
        )
      default:
        return defaultViewController
      }
    }

    return defaultViewController
  }

  private func visit(viewController: UIViewController, with options: VisitOptions, modal: Bool = false) {
    guard let visitable = viewController as? Visitable else { return }

    if modal {
      modalSession.visit(visitable, options: options)
    } else {
      session.visit(visitable, options: options)
    }
  }
}
