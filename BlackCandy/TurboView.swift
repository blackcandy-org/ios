import UIKit
import SwiftUI
import Turbo

struct TurboView: UIViewControllerRepresentable {
  let session = Session()
  let url: String
  let navigationController = UINavigationController()

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
      navigationController.pushViewController(viewController, animated: false)
      session.visit(viewController)
    }

    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
      NSLog("didFailRequestForVisitable: \(error)")
    }
  }

  func makeUIViewController(context: Context) -> UINavigationController {
    let viewController = VisitableViewController(url: URL(string: url)!)

    navigationController.pushViewController(viewController, animated: false)
    session.delegate = context.coordinator
    session.visit(viewController)

    return navigationController
  }

  func updateUIViewController(_ visitableViewController: UINavigationController, context: Context) {
  }
}
