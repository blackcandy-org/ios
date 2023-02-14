import XCTest
@testable import BlackCandy

final class UserTests: XCTestCase {
  func testDecodeUser() throws {
    let json = """
    {
      "id": 1,
      "email": "admin@admin.com",
      "isAdmin": true
    }
    """

    let user: User = try decodeJSON(from: json)

    XCTAssertEqual(user.id, 1)
    XCTAssertEqual(user.email, "admin@admin.com")
    XCTAssertEqual(user.isAdmin, true)
  }
}
