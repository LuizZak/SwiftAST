import XCTest

@testable import SwiftAST

class KeyPathExpressionTests: XCTestCase {
    func testDescription() {
        assertDescription(
            "\\Int.self",
            .init(baseType: SwiftType.int, keyPathComponents: .base(.identifier("self", nil)))
        )
        assertDescription(
            "\\.self",
            .init(keyPathComponents: .base(.identifier("self", nil)))
        )
        assertDescription(
            "\\.[]",
            .init(keyPathComponents: .base(.postfixes(.base(.subscript([])))))
        )
        assertDescription(
            "\\.[0]?!",
            .init(keyPathComponents: .base(.postfixes(.base(.subscript([.unlabeled(.constant(0))])).appendingPostfix(.safeUnwrap).appendingPostfix(.forceUnwrap))))
        )
        assertDescription(
            "\\.[0]?!.prop",
            .init(keyPathComponents: .base(.postfixes(.base(.subscript([.unlabeled(.constant(0))])).appendingPostfix(.safeUnwrap).appendingPostfix(.forceUnwrap))).appendingComponent(.identifier("prop")))
        )
        assertDescription(
            "\\Array<Int>.count.description",
            .init(baseType: SwiftType.generic("Array", parameters: [.type(.int)]), keyPathComponents: .base(.identifier("count")).appendingComponent(.identifier("description")))
        )
    }

    // MARK: - Test utils
    func assertDescription(_ expected: String, _ exp: KeyPathExpression, line: UInt = #line) {
        XCTAssertEqual(expected, exp.description, line: line)
    }
}
