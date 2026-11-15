import XCTest

@testable import SwiftAST

class IdentifierExpressionTests: XCTestCase {
    func testEquality() {
        let exp1 = Expression.identifier("a")
        let exp2 = Expression.identifier("a")
        let exp3 = Expression.identifier("a", argumentNames: ["foo"])
        let exp4 = Expression.identifier("a", argumentNames: ["foo"])

        XCTAssertEqual(exp1, exp2)
        XCTAssertEqual(exp3, exp4)
        XCTAssertNotEqual(exp1, exp3)
        XCTAssertNotEqual(exp2, exp3)
    }
}
