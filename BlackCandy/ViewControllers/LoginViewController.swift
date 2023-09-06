import Foundation
import ComposableArchitecture
import SwiftUI

class LoginViewController: UIHostingController<LoginView> {
  init(store: StoreOf<AppReducer>) {
    super.init(rootView: LoginView(
      store: store.scope(state: \.login, action: AppReducer.Action.login)
    ))
  }

  @MainActor required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
