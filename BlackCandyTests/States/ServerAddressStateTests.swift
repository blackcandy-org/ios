import XCTest
@testable import BlackCandy

final class ServerAddressStateTests: XCTestCase {
  func testIfHasEmptyField() throws {
    let state = ServerAddressState()
    XCTAssertTrue(state.hasEmptyField)

    state.url = "http://localhost:3000"
    XCTAssertFalse(state.hasEmptyField)
  }

  func testEquatable() throws {
    let state1 = ServerAddressState()
    let state2 = ServerAddressState()

    state1.url = "http://localhost:3000"
    state2.url = "http://localhost:3000"
    XCTAssertEqual(state1, state2)

    state2.url = "http://localhost:4000"
    XCTAssertNotEqual(state1, state2)
  }

  func testHasValidUrl() throws {
    let state = ServerAddressState()

    state.url = "erro yyy"
    XCTAssertFalse(state.validateUrl())

    state.url = "http://foobar.com"
    XCTAssertTrue(state.validateUrl())

    state.url = "localhost:3000"
    XCTAssertTrue(state.validateUrl())
  }

  func testAutomaticllyAddHttpSchemeAfterChekUrlValidation() throws {
    let state = ServerAddressState()

    state.url = "localhost:3000"
    XCTAssertTrue(state.validateUrl())
    XCTAssertEqual(state.url, "http://localhost:3000")
  }
}
