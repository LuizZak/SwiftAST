import XCTest

@testable import SwiftAST

class Statement_MatcherTests: XCTestCase {
    func testMatchIfHasElse() {
        let sut = hasElse()

        XCTAssertFalse(sut.matches(Statement.if(.identifier("a"), body: [])))
        XCTAssertTrue(sut.matches(Statement.if(.identifier("a"), body: [], else: [])))
        XCTAssertTrue(sut.matches(
            Statement.if(
                .identifier("a"),
                body: [],
                elseIf: .if(.identifier("b"), body: [])
            )
        ))
    }
}
