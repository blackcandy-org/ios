import SwiftUI
import ComposableArchitecture

struct SideBarView: View {
  let store: StoreOf<PlayerReducer>

  var body: some View {
    VStack {
      SideBarNavigationView()
      Divider()
      PlayerView(store: store)
    }
    .background(Color.init(.secondarySystemBackground))
  }
}
