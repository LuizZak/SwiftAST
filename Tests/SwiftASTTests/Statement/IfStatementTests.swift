import XCTest

@testable import SwiftAST

class IfExpressionTests: XCTestCase {
    func testIfLet() {
        let sut = IfExpression.ifLet(.identifier("a"), .identifier("b"), body: [
            .expression(.identifier("c")),
        ])

        XCTAssertEqual(sut.conditionalClauses.clauses, [
            .init(
                pattern: .valueBindingPattern(constant: true, .identifier("a")),
                expression: .identifier("b")
            ),
        ])
        XCTAssertEqual(sut.body, [
            .expression(.identifier("c"))
        ])
    }
}
