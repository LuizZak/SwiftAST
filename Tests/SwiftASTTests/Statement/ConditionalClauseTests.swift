import XCTest

@testable import SwiftAST

class ConditionalClauseTests: XCTestCase {
    func testParent() {
        let pattern = Pattern.expression(.identifier("b"))
        let exp = Expression.identifier("a")
        let clause = makeElement(pattern: pattern, expression: exp)

        let sut = makeSut([clause])

        XCTAssertIdentical(sut, clause.parent)
        XCTAssertIdentical(clause, pattern.subExpressions[0].parent)
        XCTAssertIdentical(clause, exp.parent)
    }
}

// MARK: - Test internals

private func makeSut(_ clauses: [ConditionalClauseElement]) -> ConditionalClauses {
    .init(clauses: clauses)
}

private func makeElement(pattern: Pattern? = nil, expression: Expression) -> ConditionalClauseElement {
    .init(pattern: pattern, expression: expression)
}
