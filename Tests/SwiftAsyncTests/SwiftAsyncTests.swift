import XCTest
@testable import SwiftAsync

class SwiftAsyncTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(SwiftAsync().text, "Hello, World!")
    }


    static var allTests : [(String, (SwiftAsyncTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
