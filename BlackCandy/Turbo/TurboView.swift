import UIKit
import SwiftUI
import Turbo
import ComposableArchitecture

struct TurboView: UIViewControllerRepresentable {
  @Environment(\.serverAddress) var serverAddress

  let viewStore: ViewStore<AppState, AppAction>
  let path: String
  var hasSearchBar = true
  var hasNavigationBar = true

  let navigationController = TurboNavigationController()
  let session = TurboSession.create()

  var url: URL {
    serverAddress!.appendingPathComponent(path)
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(
      navigationController: self.navigationController,
      viewStore: self.viewStore
    )
  }

  class Coordinator: NSObject, SessionDelegate {
    var navigationController: UINavigationController
    var viewStore: ViewStore<AppState, AppAction>

    init(navigationController: UINavigationController, viewStore: ViewStore<AppState, AppAction>) {
      self.navigationController = navigationController
      self.viewStore = viewStore
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
            viewStore.send(.updateCurrentSession(session))
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
    viewController.hasSearchBar = hasSearchBar

    navigationController.setViewControllers([viewController], animated: false)
    navigationController.setNavigationBarHidden(!hasNavigationBar, animated: false)
    session.delegate = context.coordinator
    session.visit(viewController)

    return navigationController
  }

  func updateUIViewController(_ visitableViewController: UINavigationController, context: Context) {
    let viewController = TurboVisitableViewController(url: url)
    viewController.hasSearchBar = hasSearchBar

    navigationController.setViewControllers([viewController], animated: false)
    navigationController.setNavigationBarHidden(!hasNavigationBar, animated: false)
    session.visit(viewController)
  }
}
