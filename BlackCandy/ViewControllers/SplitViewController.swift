import UIKit
import ComposableArchitecture
import SwiftUI

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {
  let viewStore: ViewStoreOf<AppReducer>

  init(store: StoreOf<AppReducer>) {
    viewStore = ViewStore(store)

    super.init(style: .doubleColumn)

    let playerStore = store.scope(state: \.player, action: AppReducer.Action.player)
    let tabBarViewController = TabBarViewController(store: playerStore)
    let sidebarViewController = UIHostingController(rootView: SideBarView(store: playerStore))

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
