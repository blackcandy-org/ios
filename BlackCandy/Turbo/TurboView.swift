import UIKit
import SwiftUI
import Turbo

struct TurboView: UIViewControllerRepresentable {
  @EnvironmentObject var store: Store

  let path: String
  let navigationController = UINavigationController()
  let session = TurboSession.create()

  var url: String {
    store.state.serverUrl + path
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(navigationController: self.navigationController)
  }

  class Coordinator: NSObject, SessionDelegate {
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
      self.navigationController = navigationController
    }

    func sessionWebViewProcessDidTerminate(_ session: Session) {
    }

    func session(_ session: Session, didProposeVisit proposal: VisitProposal) {
      let viewController = VisitableViewController(url: proposal.url)
      navigationController.pushViewController(viewController, animated: true)
      session.visit(viewController)
    }

    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
      NSLog("didFailRequestForVisitable: \(error)")
    }
  }

  func makeUIViewController(context: Context) -> UINavigationController {
    let viewController = VisitableViewController(url: URL(string: url)!)

    navigationController.setViewControllers([viewController], animated: true)
    session.delegate = context.coordinator
    session.visit(viewController)

    return navigationController
  }

  func updateUIViewController(_ visitableViewController: UINavigationController, context: Context) {
    let viewController = VisitableViewController(url: URL(string: url)!)
    navigationController.setViewControllers([viewController], animated: true)
    session.visit(viewController)
  }
}
