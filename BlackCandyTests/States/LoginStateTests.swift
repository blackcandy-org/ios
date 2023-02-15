import XCTest
@testable import BlackCandy

final class LoginStateTests: XCTestCase {
  func testIfHasEmptyField() throws {
    let state = LoginState()
    XCTAssertTrue(state.hasEmptyField)

    state.email = "test@test.com"
    XCTAssertTrue(state.hasEmptyField)

    state.password = "foobar"
    XCTAssertFalse(state.hasEmptyField)
  }

  func testEquatable() throws {
    let state1 = LoginState()
    let state2 = LoginState()

    state1.email = "test@test.com"
    state1.password = "foobar"
    state2.email = "test@test.com"
    state2.password = "foobar"
    XCTAssertEqual(state1, state2)

    state2.password = "foobar1"
    XCTAssertNotEqual(state1, state2)
  }
}
