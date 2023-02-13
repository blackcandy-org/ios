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
    """.data(using: .utf8)!

    let decoder = JSONDecoder()
    let user = try decoder.decode(User.self, from: json)

    XCTAssertEqual(1, user.id)
    XCTAssertEqual("admin@admin.com", user.email)
    XCTAssertEqual(true, user.isAdmin)
  }
}
