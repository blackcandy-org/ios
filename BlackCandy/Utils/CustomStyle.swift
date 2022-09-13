import Foundation
import SwiftUI

struct CustomStyle {
  enum Spacing: CGFloat {
    case tiny = 4
    case narrow = 8
    case small = 12
    case medium = 16
    case large = 20
    case wide = 24
    case extraWide = 30
    case ultraWide = 60
    case ultraWide2x = 120
  }

  enum CornerRadius: CGFloat {
    case small = 2
    case medium = 4
    case large = 8
  }

  static let miniPlayerImageSize: CGFloat = 40

  static func spacing(_ spacing: Spacing) -> CGFloat {
    spacing.rawValue
  }

  static func cornerRadius(_ radius: CornerRadius) -> CGFloat {
    radius.rawValue
  }
}
