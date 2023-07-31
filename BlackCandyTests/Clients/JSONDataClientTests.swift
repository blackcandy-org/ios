import XCTest
@testable import BlackCandy

final class JSONDataClientTests: XCTestCase {
  var jsonDataClient: JSONDataClient!

  override func setUpWithError() throws {
    jsonDataClient = JSONDataClient.liveValue
  }

  func testDeleteCurrentUser() throws {
    let user = try users(id: 1)

    jsonDataClient.updateCurrentUser(user)
    XCTAssertEqual(self.jsonDataClient.currentUser(), user)

    jsonDataClient.deleteCurrentUser()
    XCTAssertNil(jsonDataClient.currentUser())
  }
}
