import Foundation
import UIKit
import Dependencies
import SPAlert

extension FlashMessageClient: DependencyKey {
  static let liveValue = Self(
    showMessage: { message in
      let alertView = SPAlertView(message: String(localized: message))

      alertView.subtitleLabel?.font = .preferredFont(forTextStyle: .headline)
      alertView.subtitleLabel?.textColor = .secondaryLabel
      alertView.present()
    }
  )
}
