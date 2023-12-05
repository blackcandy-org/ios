import Foundation
import UIKit
import Dependencies
import SPAlert

extension FlashMessageClient: DependencyKey {
  static func live() -> Self {
    func presentMessage(_ message: String) {
      let alertView = SPAlertView(message: message)

      alertView.subtitleLabel?.font = .preferredFont(forTextStyle: .headline)
      alertView.subtitleLabel?.textColor = .secondaryLabel
      alertView.present()
    }

    return Self(
      showLocalizedMessage: { localizedMessage in
        presentMessage(String(localized: localizedMessage))
      },

      showMessage: { message in
        presentMessage(message)
      }
    )
  }

  static let liveValue = live()
}
