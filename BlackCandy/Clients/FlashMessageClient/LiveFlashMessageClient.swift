import Foundation
import Dependencies
import AlertKit

extension FlashMessageClient: DependencyKey {
  static let liveValue = Self(
    showMessage: { message in
      AlertKitAPI.present(title: String(localized: message), style: .iOS16AppleMusic)
    }
  )
}
