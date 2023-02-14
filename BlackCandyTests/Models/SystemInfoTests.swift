import XCTest
@testable import BlackCandy

final class SystemInfoTests: XCTestCase {
  func testDecodeSystemInfo() throws {
    let json = """
    {
      "version": {
        "major": 3,
        "minor": 0,
        "patch": 0,
        "pre": "beta1"
      }
    }
    """

    let systemInfo: SystemInfo = try decodeJSON(from: json)

    XCTAssertEqual(systemInfo.version.major, 3)
    XCTAssertEqual(systemInfo.version.minor, 0)
    XCTAssertEqual(systemInfo.version.patch, 0)
    XCTAssertEqual(systemInfo.version.pre, "beta1")
    XCTAssertTrue(systemInfo.isSupported)
  }

  func testIfSystemIsSupported() throws {
    let json = """
    {
      "version": {
        "major": 2,
        "minor": 0,
        "patch": 0,
        "pre": ""
      }
    }
    """

    let unsupportedSystemInfo: SystemInfo = try decodeJSON(from: json)

    XCTAssertFalse(unsupportedSystemInfo.isSupported)
  }
}
