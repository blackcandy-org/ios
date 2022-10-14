import UIKit
import SwiftUI
import Turbo
import ComposableArchitecture

struct TurboView: UIViewControllerRepresentable {
  @Environment(\.serverAddress) var serverAddress

  let viewStore: ViewStore<AppState, AppAction>
  let path: String
  var session: Session?
  var hasSearchBar = false
  var hasNavigationBar = true

  var url: URL {
    serverAddress!.appendingPathComponent(path)
  }

  func makeCoordinator() -> Coordinator {
    .init(viewStore: viewStore, session: session)
  }

  class Coordinator: NSObject, SessionDelegate {
    var viewStore: ViewStore<AppState, AppAction>
    var navigationController: UINavigationController = TurboNavigationController()
    var session: Session

    init(viewStore: ViewStore<AppState, AppAction>, session: Session?) {
      let session: Session = session ?? TurboSession.create()

      self.viewStore = viewStore
      self.session = session
    }

    func sessionWebViewProcessDidTerminate(_ session: Session) {
      session.reload()
    }

    func session(_ session: Session, didProposeVisit proposal: VisitProposal) {
      let viewController = TurboVisitableViewController(url: proposal.url)
      navigationController.pushViewController(viewController, animated: true)
      session.visit(viewController)
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
    let session = context.coordinator.session

    viewController.hasSearchBar = hasSearchBar
    navigationController.isNavigationBarHidden = !hasNavigationBar
    navigationController.pushViewController(viewController, animated: false)

    session.delegate = context.coordinator
    session.visit(viewController)

    return navigationController
  }

  func updateUIViewController(_ navigationController: UINavigationController, context: Context) {
  }

  static func dismantleUIViewController(_ uiViewController: UINavigationController, coordinator: Coordinator) {
    uiViewController.popViewController(animated: false)
    uiViewController.viewControllers = []
    coordinator.session.webView.stopLoading()
  }
}
