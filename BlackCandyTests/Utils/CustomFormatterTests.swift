import XCTest
@testable import BlackCandy

final class CustomFormatterTests: XCTestCase {
  func testDurationFormatter() throws {
    let formatter = DurationFormatter()

    XCTAssertEqual(formatter.string(from: 9), "00:09")
    XCTAssertEqual(formatter.string(from: 90.3), "01:30")
    XCTAssertEqual(formatter.string(from: 900.3), "15:00")
    XCTAssertEqual(formatter.string(from: 9000.3), "150:00")
  }
}
