import SwiftUI
import ComposableArchitecture

struct AccountView: View {
  let store: StoreOf<AppReducer>
  let navItemTapped: (String) -> Void

  struct ViewState: Equatable {
    let currentUser: User?
    let isAdmin: Bool

    init(state: AppReducer.State) {
      self.currentUser = state.currentUser
      self.isAdmin = state.currentUser?.isAdmin ?? false
    }
  }

  var body: some View {
    WithViewStore(self.store, observe: ViewState.init) { viewStore in
      List {
        Button("label.settings") {
          navItemTapped("/setting")
        }

        if viewStore.isAdmin {
          Button("label.manageUsers") {
            navItemTapped("/users")
          }
        }

        Button("label.updateProfile") {
          navItemTapped("/users/\(viewStore.currentUser!.id)/edit")
        }

        Section {
          Button(
            role: .destructive,
            action: {
              viewStore.send(.logout)
            },
            label: {
              Text("label.logout")
            }
          )
          .frame(maxWidth: .infinity)
        }
      }
      .listStyle(.insetGrouped)
      .navigationTitle("label.account")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

struct AccountView_Previews: PreviewProvider {
  static var previews: some View {
    var state = AppReducer.State()
    state.currentUser = User(
      id: 0,
      email: "test@test.com",
      isAdmin: true
    )

    return AccountView(
      store: Store(initialState: state) {},
      navItemTapped: { _ in }
    )
  }
}
