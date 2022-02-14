import Turbo
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?
  private lazy var navigationController = TurboNavigationController()
  fileprivate let url = URL(string: "https://yourblackcandy.server")!

  func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard scene as? UIWindowScene != nil else { return }
    window!.rootViewController = navigationController
    visit(url: url)
  }

  private func visit(url: URL) {
    let viewController = VisitableViewController(url: url)
    navigationController.pushViewController(viewController, animated: false)
    session.visit(viewController)
  }

  private lazy var session: Session = {
    let session = Session()
    session.delegate = self
    return session
  }()
}

extension SceneDelegate: SessionDelegate {
  func sessionWebViewProcessDidTerminate(_ session: Session) {
  }

  func session(_ session: Session, didProposeVisit proposal: VisitProposal) {
    visit(url: proposal.url)
  }

  func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
    print("didFailRequestForVisitable: \(error)")
  }
}
