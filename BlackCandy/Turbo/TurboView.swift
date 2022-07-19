import UIKit
import SwiftUI
import Turbo
import ComposableArchitecture

struct TurboView: UIViewControllerRepresentable {
  @Environment(\.serverAddress) var serverAddress

  let store: Store<AppState, AppAction>
  let path: String
  let navigationController = TurboNavigationController()
  let session = TurboSession.create()

  var url: String {
    serverAddress + path
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(
      navigationController: self.navigationController,
      store: self.store
    )
  }

  class Coordinator: NSObject, SessionDelegate {
    var navigationController: UINavigationController
    var store: Store<AppState, AppAction>

    init(navigationController: UINavigationController, store: Store<AppState, AppAction>) {
      self.navigationController = navigationController
      self.store = store
    }

    func sessionWebViewProcessDidTerminate(_ session: Session) {
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
            let view = SessionNewView(store: store)
            let controller = UIHostingController(rootView: view)

            controller.isModalInPresentation = true
            navigationController.present(controller, animated: true)
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
    let viewController = TurboVisitableViewController(url: URL(string: url)!)
    viewController.hasSearchBar = true

    navigationController.setViewControllers([viewController], animated: true)
    session.delegate = context.coordinator
    session.visit(viewController)

    return navigationController
  }

  func updateUIViewController(_ visitableViewController: UINavigationController, context: Context) {
    let viewController = TurboVisitableViewController(url: URL(string: url)!)
    viewController.hasSearchBar = true

    navigationController.setViewControllers([viewController], animated: true)
    session.visit(viewController)
  }
}
