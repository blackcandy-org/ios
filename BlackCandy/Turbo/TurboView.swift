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

  var url: URL {
    serverAddress!.appendingPathComponent(path)
  }

  func makeCoordinator() -> Coordinator {
    .init(viewStore: viewStore)
  }

  class Coordinator: NSObject, SessionDelegate {
    var viewStore: ViewStore<AppState, AppAction>
    var navigationController: UINavigationController = TurboNavigationController()

    lazy var session: Session = {
      let session = TurboSession.create()
      session.delegate = self

      return session
    }()

    init(viewStore: ViewStore<AppState, AppAction>) {
      self.viewStore = viewStore
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
    navigationController.setViewControllers([viewController], animated: false)
    navigationController.setNavigationBarHidden(!hasNavigationBar, animated: false)

    session.visit(viewController)

    return navigationController
  }

  func updateUIViewController(_ visitableViewController: UINavigationController, context: Context) {}
}
