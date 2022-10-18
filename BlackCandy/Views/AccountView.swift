import SwiftUI
import ComposableArchitecture

struct AccountView: View {
  let store: Store<AppState, AppAction>
  let session = TurboSession.create()

  var body: some View {
    WithViewStore(self.store) { viewStore in
      NavigationView {
        VStack {
          List {
            NavigationLink(
              "label.settings",
              destination: TurboView(
                path: "/setting",
                session: session,
                hasNavigationBar: false
              )
              .navigationTitle("label.settings")
              .ignoresSafeArea(edges: .vertical)
            )

            if viewStore.isAdmin {
              NavigationLink(
                "label.manageUsers",
                destination: TurboView(
                  path: "/users",
                  session: session,
                  hasNavigationBar: false
                )
                .navigationTitle("label.manageUsers")
                .ignoresSafeArea(edges: .vertical)
              )
            }

            if viewStore.isLoggedIn {
              NavigationLink(
                "label.updateProfile",
                destination: TurboView(
                  path: "/users/\(viewStore.currentUser!.id)/edit",
                  session: session,
                  hasNavigationBar: false
                )
                .navigationTitle("label.updateProfile")
                .ignoresSafeArea(edges: .vertical)
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
