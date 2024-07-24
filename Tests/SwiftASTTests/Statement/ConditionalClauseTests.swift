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

    func testCopy_copiesMetadata() {
        let patternExp = Expression.identifier("b")
        let pattern = Pattern.expression(patternExp)
        let exp = Expression.identifier("a")
        let clause = makeElement(pattern: pattern, expression: exp)
        let sut = makeSut([clause])

        patternExp.metadata["metadata"] = 0
        exp.metadata["metadata"] = 1
        clause.metadata["metadata"] = 2
        sut.metadata["metadata"] = 3

        let copy = sut.copy()

        XCTAssertEqual(copy.clauses[0].pattern?.subExpressions[0].metadata["metadata"] as? Int, 0)
        XCTAssertEqual(copy.clauses[0].expression.metadata["metadata"] as? Int, 1)
        XCTAssertEqual(copy.clauses[0].metadata["metadata"] as? Int, 2)
        XCTAssertEqual(copy.metadata["metadata"] as? Int, 3)
    }
}

// MARK: - Test internals

private func makeSut(_ clauses: [ConditionalClauseElement]) -> ConditionalClauses {
    .init(clauses: clauses)
}

private func makeElement(pattern: Pattern? = nil, expression: Expression) -> ConditionalClauseElement {
    .init(pattern: pattern, expression: expression)
}
