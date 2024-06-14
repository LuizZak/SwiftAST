import XCTest

@testable import SwiftAST

class IfStatementTests: XCTestCase {
    func testIfLet() {
        let sut = IfStatement.ifLet(.identifier("a"), .identifier("b"), body: [
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
