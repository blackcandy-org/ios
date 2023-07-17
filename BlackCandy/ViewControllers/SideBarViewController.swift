import Foundation
import ComposableArchitecture
import SwiftUI
import UIKit

class SideBarViewController: UIViewController {
  var navViewController: SideBarNavigationViewController
  var playerViewController: UIViewController

  init(store: StoreOf<PlayerReducer>) {
    navViewController = SideBarNavigationViewController()
    playerViewController = UIHostingController(
      rootView: VStack {
        Divider()
        PlayerView(store: store)
      }
    )

    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    super.loadView()

    addChild(navViewController)
    addChild(playerViewController)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let playerView = playerViewController.view!
    let navView = navViewController.collectionView!

    navView.translatesAutoresizingMaskIntoConstraints = false
    playerView.translatesAutoresizingMaskIntoConstraints = false
    playerView.backgroundColor = navView.backgroundColor

    self.view.addSubview(navView)
    self.view.addSubview(playerView)

    NSLayoutConstraint.activate([
      playerView.heightAnchor.constraint(equalToConstant: CustomStyle.sideBarPlayerHeight),
      playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      navView.topAnchor.constraint(equalTo: view.topAnchor),
      navView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      navView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      navView.bottomAnchor.constraint(equalTo: playerView.topAnchor)
    ])
  }
}
