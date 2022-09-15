import Foundation

class DurationFormatter: DateComponentsFormatter {
  override init() {
    super.init()

    allowedUnits = [.minute, .second]
    unitsStyle = .positional
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
