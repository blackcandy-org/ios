import Foundation

class DurationFormatter: DateComponentsFormatter {
  override init() {
    super.init()

    allowedUnits = [.minute, .second]
    unitsStyle = .positional
    zeroFormattingBehavior = .pad
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func string(from seconds: Double) -> String? {
    super.string(from: TimeInterval(seconds))
  }
}
