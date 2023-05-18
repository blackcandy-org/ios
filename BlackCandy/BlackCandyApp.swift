import SwiftUI
import ComposableArchitecture
import XCTestDynamicOverlay

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
      if !_XCTIsTesting {
        HomeView(store: AppStore.shared)
          .alert(AppStore.shared.scope(state: \.alert), dismiss: .dismissAlert)
      }
    }
  }
}
