import XCTest

@testable import SwiftAST

class PatternTests: XCTestCase {
    func testValueBindingPattern_defaultConstantValue() {
        let sut = Pattern.valueBindingPattern(.identifier("a"))

        XCTAssertEqual(sut, .valueBindingPattern(constant: true, .identifier("a")))
    }

    func testSubExpressions() {
        XCTAssertEqual(Pattern.identifier("a").subExpressions, [])
        XCTAssertEqual(Pattern.wildcard.subExpressions, [])
        XCTAssertEqual(
            Pattern.expression(.identifier("a")).subExpressions,
            [
                .identifier("a"),
            ]
        )
        XCTAssertEqual(
            Pattern.tuple([Pattern.expression(.identifier("a")), Pattern.expression(.identifier("b"))]).subExpressions,
            [
                .identifier("a"),
                .identifier("b"),
            ]
        )
        XCTAssertEqual(
            Pattern.asType(Pattern.expression(.identifier("a")), .void).subExpressions,
            [
                .identifier("a"),
            ]
        )
    }

    func testSubPatternAt() {
        let pattern = SwiftAST.Pattern.tuple([
            .identifier("a"),
            .tuple([.identifier("b"), .identifier("c")]),
            .asType(.identifier("a"), .any),
        ])

        XCTAssertEqual(pattern.subPattern(at: .self), pattern)
        XCTAssertEqual(
            pattern.subPattern(at: .tuple(index: 0, pattern: .self)),
            .identifier("a")
        )
        XCTAssertEqual(
            pattern.subPattern(at: .tuple(index: 1, pattern: .tuple(index: 0, pattern: .self))),
            .identifier("b")
        )
        XCTAssertEqual(
            pattern.subPattern(at: .tuple(index: 1, pattern: .tuple(index: 1, pattern: .self))),
            .identifier("c")
        )
        XCTAssertEqual(
            pattern.subPattern(at: .tuple(index: 2, pattern: .self)),
            .asType(.identifier("a"), .any)
        )
        XCTAssertEqual(
            pattern.subPattern(at: .tuple(index: 2, pattern: .asType(pattern: .self))),
            .identifier("a")
        )
    }

    func testFailedSubPatternAt() {
        let pattern = SwiftAST.Pattern.tuple([
            .identifier("a"),
            .tuple([.identifier("b"), .identifier("c")]),
        ])

        XCTAssertNil(
            pattern.subPattern(at: .tuple(index: 0, pattern: .tuple(index: 0, pattern: .self)))
        )
        XCTAssertNil(
            pattern.subPattern(at: .tuple(index: 1, pattern: .tuple(index: 3, pattern: .self)))
        )
    }

    func testSerialize() throws {
        assertSerializeRoundabout(.identifier("a"))
        assertSerializeRoundabout(.tuple([.identifier("a")]))
        assertSerializeRoundabout(.expression(.constant(true)))
        assertSerializeRoundabout(.asType(.identifier("a"), .int))
        assertSerializeRoundabout(.valueBindingPattern(constant: true, .identifier("a")))
        assertSerializeRoundabout(.valueBindingPattern(constant: false, .identifier("b")))
    }
}

// MARK: - Test internals

private func assertSerializeRoundabout(
    _ sut: Pattern,
    file: StaticString = #file,
    line: UInt = #line
) {

    do {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(sut)
        let decodedSut = try decoder.decode(Pattern.self, from: data)

        XCTAssertEqual(sut, decodedSut, file: file, line: line)
    } catch {
        XCTFail("Unexpected error: \(error)", file: file, line: line)
    }
}
