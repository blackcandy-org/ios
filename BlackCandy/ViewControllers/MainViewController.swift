import UIKit
import ComposableArchitecture
import SwiftUI
import Combine

class MainViewController: UISplitViewController, UISplitViewControllerDelegate {
  let viewStore: ViewStoreOf<AppReducer>
  var cancellables: Set<AnyCancellable> = []

  init(store: StoreOf<AppReducer>) {
    viewStore = ViewStore(store)

    super.init(style: .doubleColumn)

    let playerStore = store.scope(state: \.player, action: AppReducer.Action.player)
    let tabBarViewController = TabBarViewController(store: playerStore)
    let sidebarViewController = SideBarViewController(store: playerStore)

    preferredDisplayMode = .oneBesideSecondary
    preferredSplitBehavior = .tile
    presentsWithGesture = false
    delegate = self

    setViewController(sidebarViewController, for: .primary)
    setViewController(tabBarViewController, for: .secondary)
    setViewController(tabBarViewController, for: .compact)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidAppear(_ animated: Bool) {
    viewStore.send(.player(.getCurrentPlaylist))
  }

  override func viewDidLoad() {
    self.viewStore.publisher.alert
      .sink { [weak self] alert in
        guard let self = self else { return }
        guard let alert = alert else { return }

        let alertController = UIAlertController(
          title: String(state: alert.title),
          message: nil,
          preferredStyle: .alert
        )

        alertController.addAction(
          UIAlertAction(title: NSLocalizedString("label.ok", comment: ""), style: .default) { _ in
            self.viewStore.send(.dismissAlert)
          }
        )

        self.present(alertController, animated: true, completion: nil)
      }
      .store(in: &self.cancellables)
  }

  func splitViewControllerDidExpand(_ svc: UISplitViewController) {
    NotificationCenter.default.post(
      name: .splitViewDidExpand,
      object: self
    )
  }

  func splitViewControllerDidCollapse(_ svc: UISplitViewController) {
    NotificationCenter.default.post(
      name: .splitViewDidCollapse,
      object: self
    )
  }
}
