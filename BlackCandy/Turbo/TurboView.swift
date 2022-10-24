import UIKit
import SwiftUI
import Turbo
import ComposableArchitecture

struct TurboView: UIViewControllerRepresentable {
  @Environment(\.serverAddress) var serverAddress

  let path: String
  var session: Session?
  var hasSearchBar = false
  var hasNavigationBar = true

  var url: URL {
    serverAddress!.appendingPathComponent(path)
  }

  func makeCoordinator() -> Coordinator {
    .init(sharedSession: session)
  }

  class Coordinator: NSObject, SessionDelegate {
    let navigationController: UINavigationController = TurboNavigationController()
    let viewStore = ViewStore(AppStore.shared.stateless, removeDuplicates: ==)
    private let sharedSession: Session?

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

    init(sharedSession: Session?) {
      self.sharedSession = sharedSession
    }

    func sessionWebViewProcessDidTerminate(_ session: Session) {
      session.reload()
    }

    func session(_ session: Session, didProposeVisit proposal: VisitProposal) {
      let viewController = TurboVisitableViewController(url: proposal.url)
      let presentation = proposal.properties["presentation"] as? String
      let visitOptions = proposal.options

      // Dismiss any modals when receiving a new navigation
      if navigationController.presentedViewController != nil {
        navigationController.dismiss(animated: true)
      }

      if presentation == "modal" {
        let modalViewController = UINavigationController(rootViewController: viewController)

        navigationController.present(modalViewController, animated: true)
        modalSession.visit(viewController, options: visitOptions)
        return
      }

      if session.activeVisitable?.visitableURL == proposal.url || visitOptions.action == .replace {
        let viewControllers = Array(navigationController.viewControllers.dropLast()) + [viewController]

        navigationController.setViewControllers(viewControllers, animated: false)
        session.visit(viewController, options: visitOptions)
        return
      }

      navigationController.pushViewController(viewController, animated: true)
      session.visit(viewController, options: visitOptions)
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
  }

  func makeUIViewController(context: Context) -> UINavigationController {
    let viewController = TurboVisitableViewController(url: url)
    let navigationController = context.coordinator.navigationController

    viewController.hasSearchBar = hasSearchBar
    navigationController.isNavigationBarHidden = !hasNavigationBar
    navigationController.pushViewController(viewController, animated: false)
    context.coordinator.viewSession.visit(viewController)

    return navigationController
  }

  func updateUIViewController(_ navigationController: UINavigationController, context: Context) {
  }

  static func dismantleUIViewController(_ uiViewController: UINavigationController, coordinator: Coordinator) {
    uiViewController.popViewController(animated: false)
    uiViewController.viewControllers = []
    coordinator.viewSession.webView.stopLoading()
  }
}
