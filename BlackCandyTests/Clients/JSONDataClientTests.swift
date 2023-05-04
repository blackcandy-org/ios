import XCTest
@testable import BlackCandy

final class JSONDataClientTests: XCTestCase {
  var jsonDataClient: JSONDataClient!

  override func setUpWithError() throws {
    jsonDataClient = JSONDataClient.live
  }

  func testDeleteCurrentUser() throws {
    let user = User(id: 1, email: "test@test.com", isAdmin: true)
    let expectation = XCTestExpectation(description: "Update Current User")

    jsonDataClient.updateCurrentUser(user) {
      XCTAssertEqual(self.jsonDataClient.currentUser(), user)
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 10.0)

    jsonDataClient.deleteCurrentUser()
    XCTAssertNil(jsonDataClient.currentUser())
  }
}
