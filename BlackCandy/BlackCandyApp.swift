import SwiftUI
import ComposableArchitecture

@main
struct BlackCandyApp: App {
  init() {
    ViewStore(AppStore.shared.stateless, removeDuplicates: ==).send(.restoreStates)

    let navigationBarAppearance = UINavigationBarAppearance()
    navigationBarAppearance.configureWithDefaultBackground()

    UINavigationBar.appearance().standardAppearance = navigationBarAppearance
    UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance

    AudioSessionControl.shared.setup()
    RemoteControl.shared.setup()
  }

  var body: some Scene {
    WindowGroup {
      ContentView(store: AppStore.shared)
        .alert(AppStore.shared.scope(state: \.alert), dismiss: .dismissAlert)
    }
  }
}
