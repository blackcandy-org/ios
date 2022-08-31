import SwiftUI
import ComposableArchitecture

struct AccountView: View {
  let store: Store<AppState, AppAction>

  var body: some View {
    WithViewStore(self.store) { viewStore in
      NavigationView {
        VStack {
          List {
            NavigationLink(
              "label.settings",
              destination: TurboView(
                viewStore: viewStore,
                path: "/setting",
                hasSearchBar: false,
                hasNavigationBar: false
              ).navigationTitle("label.settings")
            )

            if viewStore.isAdmin {
              NavigationLink(
                "label.manageUsers",
                destination: TurboView(
                  viewStore: viewStore,
                  path: "/users",
                  hasSearchBar: false,
                  hasNavigationBar: false
                ).navigationTitle("label.manageUsers")
              )
            }

            if viewStore.isLoggedIn {
              NavigationLink(
                "label.updateProfile",
                destination: TurboView(
                  viewStore: viewStore,
                  path: "/users/\(viewStore.currentUser!.id)/edit",
                  hasSearchBar: false,
                  hasNavigationBar: false
                ).navigationTitle("label.updateProfile")
              )
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
        }
        .navigationTitle("label.account")
        .navigationBarTitleDisplayMode(.inline)
      }
      .navigationViewStyle(.stack)
    }
  }
}
