import XCTest

@testable import SwiftAST

class GuardStatementTests: XCTestCase {
    func testGuardLet() {
        let sut = GuardStatement.guardLet(.identifier("a"), .identifier("b"), else: [
            .expression(.identifier("c")),
        ])

        XCTAssertEqual(sut.conditionalClauses.clauses, [
            .init(
                pattern: .valueBindingPattern(constant: true, .identifier("a")),
                expression: .identifier("b")
            ),
        ])
        XCTAssertEqual(sut.elseBody, [
            .expression(.identifier("c"))
        ])
    }
}
