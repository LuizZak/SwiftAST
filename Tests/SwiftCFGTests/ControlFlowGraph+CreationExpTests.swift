import SwiftAST
import XCTest

@testable import SwiftAST
@testable import SwiftCFG

class ControlFlowGraph_CreationExpTests: XCTestCase {
    override func setUp() {
        // recordMode = true
    }

    override class func tearDown() {
        super.tearDown()

        do {
            try updateAllRecordedGraphviz()
        } catch {
            print("Error updating test list: \(error)")
        }
    }

    override func tearDownWithError() throws {
        try throwErrorIfInGraphvizRecordMode()

        try super.tearDownWithError()
    }

    func testExpression_arrayLiteral() {
        let exp: SwiftAST.Expression = .arrayLiteral([
                .identifier("a"),
                .identifier("b"),
                .identifier("c"),
            ])

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="b"]
                    n4 [label="c"]
                    n5 [label="[a, b, c]"]
                    n6 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_assignment() {
        let exp: SwiftAST.Expression =
            .identifier("a").assignment(op: .assign, rhs: .identifier("b"))

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="b"]
                    n4 [label="a = b"]
                    n5 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_assignment_optionalShortCircuiting() {
        let exp: SwiftAST.Expression =
            .identifier("a").optional().dot("b").assignment(op: .assign, rhs: .identifier("c"))

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="a?.b"]
                    n4 [label="c"]
                    n5 [label="a?.b = c"]
                    n6 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n3 -> n6
                    n5 -> n6
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testExpression_assignment_optionalShortCircuiting_rightSide() {
        let exp: SwiftAST.Expression =
            .identifier("a").optional().dot("b").assignment(op: .assign, rhs: .identifier("c").optional().dot("d").optional().dot("e"))

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="a?.b"]
                    n4 [label="c"]
                    n5 [label="c?.d"]
                    n6 [label="c?.d?.e"]
                    n7 [label="a?.b = c?.d?.e"]
                    n8 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n5 -> n7
                    n6 -> n7
                    n3 -> n8
                    n7 -> n8
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testExpression_blockLiteral() {
        let exp: SwiftAST.Expression =
            .block(body: [])

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{ () -> Void in < body > }"]
                    n3 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_cast() {
        let exp: SwiftAST.Expression =
            .cast(.identifier("a"), type: .int)

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="a as? Int"]
                    n4 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_cast_shortCircuit() {
        let exp: SwiftAST.Expression =
            .cast(.identifier("a").binary(op: .nullCoalesce, rhs: .identifier("b")), type: .int)

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="b"]
                    n4 [label="a ?? b"]
                    n5 [label="a ?? b as? Int"]
                    n6 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n2 -> n4
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_constant() {
        let exp: SwiftAST.Expression =
            .constant(0)

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="0"]
                    n3 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_dictionaryLiteral() {
        let exp: SwiftAST.Expression =
            .dictionaryLiteral([
                .identifier("a"): .identifier("b"),
                .identifier("c"): .identifier("d"),
                .identifier("e"): .identifier("f"),
            ])

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="b"]
                    n4 [label="c"]
                    n5 [label="d"]
                    n6 [label="e"]
                    n7 [label="f"]
                    n8 [label="[a: b, c: d, e: f]"]
                    n9 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_identifier() {
        let exp: SwiftAST.Expression =
            .identifier("a")

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_parens() {
        let exp: SwiftAST.Expression =
            .parens(.identifier("a").call())

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="a()"]
                    n4 [label="(a())"]
                    n5 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_parens_shortCircuit() {
        let exp: SwiftAST.Expression =
            .parens(.identifier("a").optional().call().optional().dot("b"))

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="a?()"]
                    n4 [label="a?()?.b"]
                    n5 [label="(a?()?.b)"]
                    n6 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n3 -> n5
                    n4 -> n5
                    n5 -> n6
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_postfix_member() {
        let exp: SwiftAST.Expression =
            .identifier("a").dot("b")

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="a.b"]
                    n4 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_postfix_member_argumentNames() {
        let exp: SwiftAST.Expression =
            .identifier("a").dot("b", argumentNames: ["c", "_"])

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="a.b(c:_:)"]
                    n4 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_postfix_call_noArguments() {
        let exp: SwiftAST.Expression =
            .identifier("a").call()

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="a()"]
                    n4 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_postfix_call_withArguments() {
        let exp: SwiftAST.Expression =
            .identifier("a").call([.identifier("b"), .identifier("c")])

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="b"]
                    n4 [label="c"]
                    n5 [label="a(b, c)"]
                    n6 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_postfix_call_withArguments_shortCircuit() {
        let exp: SwiftAST.Expression =
            .identifier("a").call([.identifier("b"), .identifier("c").binary(op: .nullCoalesce, rhs: .constant(0)), .identifier("d")])

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="b"]
                    n4 [label="c"]
                    n5 [label="0"]
                    n6 [label="c ?? 0"]
                    n7 [label="d"]
                    n8 [label="a(b, c ?? 0, d)"]
                    n9 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n4 -> n6
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_postfix_subscript() {
        let exp: SwiftAST.Expression =
            .identifier("a").sub(.constant(0))

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="0"]
                    n4 [label="a[0]"]
                    n5 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_postfix_subscript_shortCircuit() {
        let exp: SwiftAST.Expression =
            .identifier("a").sub(.identifier("b").binary(op: .nullCoalesce, rhs: .constant(0)))

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="b"]
                    n4 [label="0"]
                    n5 [label="b ?? 0"]
                    n6 [label="a[b ?? 0]"]
                    n7 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n3 -> n5
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_postfix_optional() {
        let exp: SwiftAST.Expression =
            .identifier("a").optional().dot("b").optional().sub(.constant(0)).optional().call()

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="a?.b"]
                    n4 [label="0"]
                    n5 [label="a?.b?[0]"]
                    n6 [label="a?.b?[0]?()"]
                    n7 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n3 -> n7
                    n5 -> n7
                    n6 -> n7
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 3)
    }

    func testExpression_prefix() {
        let exp: SwiftAST.Expression =
            .prefix(op: .subtract, .identifier("a"))

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="-a"]
                    n4 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_prefix_shortCircuit() {
        let exp: SwiftAST.Expression =
            .prefix(op: .subtract, .identifier("a").binary(op: .nullCoalesce, rhs: .identifier("b")))

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="b"]
                    n4 [label="a ?? b"]
                    n5 [label="-(a ?? b)"]
                    n6 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n2 -> n4
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_selector() {
        let exp: SwiftAST.Expression =
            .selector(getter: "a")

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="#selector(getter: a)"]
                    n3 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_sizeOf_expression() {
        let exp: SwiftAST.Expression =
            .sizeof(.identifier("a"))

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="MemoryLayout.size(ofValue: a)"]
                    n4 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_sizeOf_expression_shortCircuit() {
        let exp: SwiftAST.Expression =
            .identifier("print").call([.sizeof(.identifier("a").binary(op: .nullCoalesce, rhs: .constant(0)))])

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="print"]
                    n3 [label="a"]
                    n4 [label="0"]
                    n5 [label="a ?? 0"]
                    n6 [label="MemoryLayout.size(ofValue: a ?? 0)"]
                    n7 [label="print(MemoryLayout.size(ofValue: a ?? 0))"]
                    n8 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n3 -> n5
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_sizeOf_type() {
        let exp: SwiftAST.Expression =
            .sizeof(type: "A")

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="MemoryLayout<A>.size"]
                    n3 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_ternaryExpression() {
        let exp: SwiftAST.Expression =
            .ternary(
                .identifier("a"),
                true: .identifier("b"),
                false: .identifier("c")
            )

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="a ? b : c"]
                    n4 [label="b"]
                    n5 [label="c"]
                    n6 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n3 -> n5
                    n4 -> n6
                    n5 -> n6
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testExpression_ternaryExpression_shortCircuit() {
        let exp: SwiftAST.Expression =
            .ternary(
                .identifier("a"),
                true: .identifier("b").binary(op: .nullCoalesce, rhs: .identifier("c")),
                false: .identifier("d")
            )

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="a ? b ?? c : d"]
                    n4 [label="b"]
                    n5 [label="d"]
                    n6 [label="c"]
                    n7 [label="b ?? c"]
                    n8 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n3 -> n5
                    n4 -> n6
                    n4 -> n7
                    n6 -> n7
                    n5 -> n8
                    n7 -> n8
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testExpression_try() {
        let exp: SwiftAST.Expression =
            .try(.identifier("a"))

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [fillcolor="#DDDDFF", label="{marker}", style=filled]
                    n4 [fillcolor="#DDDDFF", label="{marker}", style=filled]
                    n5 [label="try a"]
                    n6 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_try_optional() {
        let exp: SwiftAST.Expression =
            .try(.identifier("a"), mode: .optional)

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [fillcolor="#DDDDFF", label="{marker}", style=filled]
                    n4 [fillcolor="#DDDDFF", label="{marker}", style=filled]
                    n5 [label="try? a"]
                    n6 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_try_forced() {
        let exp: SwiftAST.Expression =
            .try(.identifier("a"), mode: .forced)

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [fillcolor="#DDDDFF", label="{marker}", style=filled]
                    n4 [fillcolor="#DDDDFF", label="{marker}", style=filled]
                    n5 [label="try! a"]
                    n6 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_try_errorFlow() {
        let stmt: CompoundStatement = [
            .do([
                .expression(
                    .try(.identifier("a"))
                ),
                .expression(.identifier("postTry")),
            ]).catch([
                .expression(.identifier("errorHandler")),
            ]),
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{do}"]
                    n4 [label="{compound}"]
                    n5 [label="{exp}"]
                    n6 [label="a"]
                    n7 [label="try a"]
                    n8 [label="{catch}"]
                    n9 [label="{exp}"]
                    n10 [label="{compound}"]
                    n11 [label="postTry"]
                    n12 [label="{exp}"]
                    n13 [label="errorHandler"]
                    n14 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8 [label="throws"]
                    n7 -> n9
                    n8 -> n10
                    n9 -> n11
                    n10 -> n12
                    n12 -> n13
                    n11 -> n14
                    n13 -> n14
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testExpression_try_optional_noErrorFlow() {
        let stmt: CompoundStatement = [
            .do([
                .expression(
                    .try(.identifier("a"), mode: .optional)
                ),
                .expression(.identifier("postTry")),
            ]).catch([
                .expression(.identifier("errorHandler")),
            ]),
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph, expectsUnreachable: true)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{do}"]
                    n4 [label="{compound}"]
                    n5 [label="{exp}"]
                    n6 [label="a"]
                    n7 [label="try? a"]
                    n8 [label="{exp}"]
                    n9 [label="postTry"]
                    n10 [label="{catch}"]
                    n11 [label="{compound}"]
                    n12 [label="{exp}"]
                    n13 [label="errorHandler"]
                    n14 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9
                    n10 -> n11
                    n11 -> n12
                    n12 -> n13
                    n9 -> n14
                    n13 -> n14
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testExpression_try_shortCircuit() {
        let exp: SwiftAST.Expression =
            .identifier("a").call([
                .try(.identifier("b").binary(op: .nullCoalesce, rhs: .identifier("c")))
            ])

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="b"]
                    n4 [label="c"]
                    n5 [label="b ?? c"]
                    n6 [label="try b ?? c"]
                    n7 [label="a(try b ?? c)"]
                    n8 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n3 -> n5
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n6 -> n8 [label="throws"]
                    n7 -> n8
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testExpression_tuple() {
        let exp: SwiftAST.Expression =
            .tuple([
                .identifier("a"),
                .identifier("b"),
                .identifier("c"),
            ])

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="b"]
                    n4 [label="c"]
                    n5 [label="(a, b, c)"]
                    n6 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_tuple_shortCircuit() {
        let exp: SwiftAST.Expression =
            .tuple([
                .identifier("a").binary(op: .nullCoalesce, rhs: .identifier("b")),
                .identifier("c"),
                .identifier("d").binary(op: .and, rhs: .identifier("e")),
            ])

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="b"]
                    n4 [label="a ?? b"]
                    n5 [label="c"]
                    n6 [label="d"]
                    n7 [label="e"]
                    n8 [label="d && e"]
                    n9 [label="(a ?? b, c, d && e)"]
                    n10 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n2 -> n4
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n6 -> n8
                    n7 -> n8
                    n8 -> n9
                    n9 -> n10
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_typeCheck() {
        let exp: SwiftAST.Expression =
            .typeCheck(.identifier("a"), type: .int)

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="a is Int"]
                    n4 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_typeCheck_shortCircuit() {
        let exp: SwiftAST.Expression =
            .typeCheck(.identifier("a").binary(op: .nullCoalesce, rhs: .identifier("b")), type: .int)

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="b"]
                    n4 [label="a ?? b"]
                    n5 [label="a ?? b is Int"]
                    n6 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n2 -> n4
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_unary() {
        let exp: SwiftAST.Expression =
            .unary(op: .subtract, .identifier("a"))

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="-a"]
                    n4 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_unary_shortCircuit() {
        let exp: SwiftAST.Expression =
            .unary(op: .subtract, .identifier("a").binary(op: .nullCoalesce, rhs: .identifier("b")))

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="b"]
                    n4 [label="a ?? b"]
                    n5 [label="-(a ?? b)"]
                    n6 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n2 -> n4
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_if() {
        let stmt: CompoundStatement = [
            Statement.if(
                .identifier("predicate"),
                body: [
                    .expression(.identifier("ifBody")),
                ]
            ),
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{exp}"]
                    n4 [label="{if}"]
                    n5 [label="predicate"]
                    n6 [label="{if predicate}"]
                    n7 [label="{compound}"]
                    n8 [label="{exp}"]
                    n9 [label="ifBody"]
                    n10 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7 [label="true"]
                    n7 -> n8
                    n8 -> n9
                    n6 -> n10 [label="false"]
                    n9 -> n10
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testExpression_if_withElse() {
        let stmt: CompoundStatement = [
            Statement.if(
                .identifier("predicate"),
                body: [
                    .expression(.identifier("ifBody")),
                ],
                else: [
                    .expression(.identifier("elseBody")),
                ]
            ),
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{exp}"]
                    n4 [label="{if}"]
                    n5 [label="predicate"]
                    n6 [label="{if predicate}"]
                    n7 [label="{compound}"]
                    n8 [label="{compound}"]
                    n9 [label="{exp}"]
                    n10 [label="{exp}"]
                    n11 [label="elseBody"]
                    n12 [label="ifBody"]
                    n13 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7 [label="true"]
                    n6 -> n8 [label="false"]
                    n7 -> n9
                    n8 -> n10
                    n10 -> n11
                    n9 -> n12
                    n11 -> n13
                    n12 -> n13
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testExpression_if_withElseIf() {
        let stmt: CompoundStatement = [
            .if(
                .identifier("predicate"),
                body: [
                    .expression(.identifier("ifBody")),
                ],
                elseIf: .if(
                    .identifier("predicate2"),
                    body: [
                        .expression(.identifier("ifElseIfBody")),
                    ],
                    else: [
                        .expression(.identifier("ifElseIfElseBody")),
                    ]
                )
            ),
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{exp}"]
                    n4 [label="{if}"]
                    n5 [label="predicate"]
                    n6 [label="{if predicate}"]
                    n7 [label="{if}"]
                    n8 [label="{compound}"]
                    n9 [label="predicate2"]
                    n10 [label="{exp}"]
                    n11 [label="{if predicate2}"]
                    n12 [label="ifBody"]
                    n13 [label="{compound}"]
                    n14 [label="{compound}"]
                    n15 [label="{exp}"]
                    n16 [label="{exp}"]
                    n17 [label="ifElseIfBody"]
                    n18 [label="ifElseIfElseBody"]
                    n19 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7 [label="false"]
                    n6 -> n8 [label="true"]
                    n7 -> n9
                    n8 -> n10
                    n9 -> n11
                    n10 -> n12
                    n11 -> n13 [label="true"]
                    n11 -> n14 [label="false"]
                    n13 -> n15
                    n14 -> n16
                    n15 -> n17
                    n16 -> n18
                    n12 -> n19
                    n17 -> n19
                    n18 -> n19
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 3)
    }

    func testExpression_if_labeledBreak() {
        let stmt: CompoundStatement = [
            .while(.identifier("whilePredicate"), body: [
                .if(
                    .identifier("predicate"),
                    body: [
                        .if(.identifier("predicateInner"), body: [
                            .break(targetLabel: "outer"),
                            .expression(.identifier("postBreak")),
                        ]),
                    ]
                ).labeled("outer"),
            ]),
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph, expectsUnreachable: true)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{while}"]
                    n4 [label="whilePredicate"]
                    n5 [label="{if whilePredicate}"]
                    n6 [label="{compound}"]
                    n7 [label="{exp}"]
                    n8 [label="{if}"]
                    n9 [label="predicate"]
                    n10 [label="{if predicate}"]
                    n11 [label="{compound}"]
                    n12 [label="{exp}"]
                    n13 [label="{if}"]
                    n14 [label="predicateInner"]
                    n15 [label="{if predicateInner}"]
                    n16 [label="{compound}"]
                    n17 [label="{break outer}"]
                    n18 [label="{exp}"]
                    n19 [label="postBreak"]
                    n20 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n10 -> n3 [color="#aa3333", label="false", penwidth=0.5]
                    n15 -> n3 [color="#aa3333", label="false", penwidth=0.5]
                    n17 -> n3 [color="#aa3333", penwidth=0.5]
                    n19 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6 [label="true"]
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9
                    n9 -> n10
                    n10 -> n11 [label="true"]
                    n11 -> n12
                    n12 -> n13
                    n13 -> n14
                    n14 -> n15
                    n15 -> n16 [label="true"]
                    n16 -> n17
                    n18 -> n19
                    n5 -> n20 [label="false"]
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_if_multiClause() {
        let stmt: CompoundStatement = [
            Statement.if(
                clauses: [
                    .init(expression: .identifier("predicate1")),
                    .init(
                        pattern: .expression(.identifier("pattern2")),
                        expression: .identifier("predicate2")
                    ),
                ],
                body: [
                    .expression(.identifier("ifBody")),
                ]
            ),
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{exp}"]
                    n4 [label="{if}"]
                    n5 [label="predicate1"]
                    n6 [label="{if predicate1}"]
                    n7 [label="pattern2"]
                    n8 [label="predicate2"]
                    n9 [label="{if pattern2 = predicate2}"]
                    n10 [label="{compound}"]
                    n11 [label="{exp}"]
                    n12 [label="ifBody"]
                    n13 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7 [label="true"]
                    n7 -> n8
                    n8 -> n9
                    n9 -> n10 [label="true"]
                    n10 -> n11
                    n11 -> n12
                    n6 -> n13 [label="false"]
                    n9 -> n13 [label="false"]
                    n12 -> n13
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 3)
    }

    func testExpression_if_multiClause_throwingExpression() {
        let stmt: CompoundStatement = [
            Statement.do([
                Statement.if(
                    clauses: [
                        .init(expression: .identifier("predicate1")),
                        .init(
                            pattern: .expression(.identifier("pattern2")),
                            expression: .try(.identifier("predicate2"))
                        ),
                    ],
                    body: [
                        .expression(.identifier("ifBody")),
                    ]
                ),
            ]).catch([
                .expression(.identifier("catch_clause"))
            ])
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{do}"]
                    n4 [label="{compound}"]
                    n5 [label="{exp}"]
                    n6 [label="{if}"]
                    n7 [label="predicate1"]
                    n8 [label="{if predicate1}"]
                    n9 [label="pattern2"]
                    n10 [label="predicate2"]
                    n11 [label="try predicate2"]
                    n12 [label="{catch}"]
                    n13 [label="{if pattern2 = try predicate2}"]
                    n14 [label="{compound}"]
                    n15 [label="{compound}"]
                    n16 [label="{exp}"]
                    n17 [label="{exp}"]
                    n18 [label="catch_clause"]
                    n19 [label="ifBody"]
                    n20 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9 [label="true"]
                    n9 -> n10
                    n10 -> n11
                    n11 -> n12 [label="throws"]
                    n11 -> n13
                    n13 -> n14 [label="true"]
                    n12 -> n15
                    n14 -> n16
                    n15 -> n17
                    n17 -> n18
                    n16 -> n19
                    n8 -> n20 [label="false"]
                    n13 -> n20 [label="false"]
                    n18 -> n20
                    n19 -> n20
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 4)
    }

    func testExpression_if_multiClause_throwingPattern() {
        let stmt: CompoundStatement = [
            Statement.do([
                Statement.if(
                    clauses: [
                        .init(expression: .identifier("predicate1")),
                        .init(
                            pattern: .expression(.try(.identifier("pattern2"))),
                            expression: .identifier("predicate2")
                        ),
                    ],
                    body: [
                        .expression(.identifier("ifBody")),
                    ]
                ),
            ]).catch([
                .expression(.identifier("catch_clause"))
            ])
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{do}"]
                    n4 [label="{compound}"]
                    n5 [label="{exp}"]
                    n6 [label="{if}"]
                    n7 [label="predicate1"]
                    n8 [label="{if predicate1}"]
                    n9 [label="pattern2"]
                    n10 [label="try pattern2"]
                    n11 [label="{catch}"]
                    n12 [label="predicate2"]
                    n13 [label="{compound}"]
                    n14 [label="{if try pattern2 = predicate2}"]
                    n15 [label="{compound}"]
                    n16 [label="{exp}"]
                    n17 [label="{exp}"]
                    n18 [label="catch_clause"]
                    n19 [label="ifBody"]
                    n20 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9 [label="true"]
                    n9 -> n10
                    n10 -> n11 [label="throws"]
                    n10 -> n12
                    n11 -> n13
                    n12 -> n14
                    n14 -> n15 [label="true"]
                    n13 -> n16
                    n15 -> n17
                    n16 -> n18
                    n17 -> n19
                    n8 -> n20 [label="false"]
                    n14 -> n20 [label="false"]
                    n18 -> n20
                    n19 -> n20
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 4)
    }

    func testExpression_if_asExpression_assignment() throws {
        let exp = #ast_expandExpression(firstExpressionIn: { (a: inout Int) in
            a = if (a == 1) { 1 } else { 2 }
        })

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="{if}"]
                    n4 [label="a"]
                    n5 [label="1"]
                    n6 [label="a == 1"]
                    n7 [label="(a == 1)"]
                    n8 [label="{if (a == 1)}"]
                    n9 [label="{compound}"]
                    n10 [label="{compound}"]
                    n11 [label="{exp}"]
                    n12 [label="{exp}"]
                    n13 [label="1"]
                    n14 [label="2"]
                    n15 [label="a = IfExpression"]
                    n16 [label="exit"]

                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9 [label="true"]
                    n8 -> n10 [label="false"]
                    n9 -> n11
                    n10 -> n12
                    n11 -> n13
                    n12 -> n14
                    n13 -> n15
                    n14 -> n15
                    n15 -> n16
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_switch() {
        let stmt: CompoundStatement = [
            Statement.switch(
                .identifier("switchExp"),
                cases: [
                    SwitchCase(
                        patterns: [
                            .identifier("patternA"),
                        ],
                        statements: [
                            .expression(.identifier("case1")),
                        ]
                    ),
                    SwitchCase(
                        patterns: [
                            .identifier("patternB"),
                        ],
                        statements: [
                            .expression(.identifier("case2")),
                        ]
                    ),
                ],
                default: nil
            )
        ]
        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{exp}"]
                    n4 [label="switchExp"]
                    n5 [label="SwitchExpression"]
                    n6 [label="{case patternA}"]
                    n7 [label="{case patternB}"]
                    n8 [label="{compound}"]
                    n9 [label="{compound}"]
                    n10 [label="{exp}"]
                    n11 [label="{exp}"]
                    n12 [label="case1"]
                    n13 [label="case2"]
                    n14 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7 [label="pattern fail"]
                    n6 -> n8 [label="pattern success"]
                    n7 -> n9 [label="pattern success"]
                    n8 -> n10
                    n9 -> n11
                    n10 -> n12
                    n11 -> n13
                    n12 -> n14
                    n13 -> n14
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testExpression_switch_withDefaultCase() {
        let stmt: CompoundStatement = [
            Statement.switch(
                .identifier("switchExp"),
                cases: [
                    SwitchCase(
                        patterns: [.identifier("patternA")],
                        statements: [
                            .expression(.identifier("b")),
                        ]
                    ),
                    SwitchCase(
                        patterns: [.identifier("patternB")],
                        statements: [
                            .expression(.identifier("c")),
                        ]
                    ),
                    SwitchCase(
                        patterns: [.identifier("patternC")],
                        statements: [
                            .expression(.identifier("d")),
                        ]
                    ),
                    SwitchCase(
                        patterns: [.identifier("patternD")],
                        statements: [
                            .expression(.identifier("e")),
                        ]
                    ),
                ],
                defaultStatements: [
                    .expression(.identifier("defaultCase")),
                ]
            )
        ]
        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{exp}"]
                    n4 [label="switchExp"]
                    n5 [label="SwitchExpression"]
                    n6 [label="{case patternA}"]
                    n7 [label="{case patternB}"]
                    n8 [label="{compound}"]
                    n9 [label="{case patternC}"]
                    n10 [label="{compound}"]
                    n11 [label="{exp}"]
                    n12 [label="{case patternD}"]
                    n13 [label="{compound}"]
                    n14 [label="{exp}"]
                    n15 [label="b"]
                    n16 [label="{default}"]
                    n17 [label="{compound}"]
                    n18 [label="{exp}"]
                    n19 [label="c"]
                    n20 [label="{compound}"]
                    n21 [label="{exp}"]
                    n22 [label="d"]
                    n23 [label="{exp}"]
                    n24 [label="e"]
                    n25 [label="defaultCase"]
                    n26 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7 [label="pattern fail"]
                    n6 -> n8 [label="pattern success"]
                    n7 -> n9 [label="pattern fail"]
                    n7 -> n10 [label="pattern success"]
                    n8 -> n11
                    n9 -> n12 [label="pattern fail"]
                    n9 -> n13 [label="pattern success"]
                    n10 -> n14
                    n11 -> n15
                    n12 -> n16 [label="pattern fail"]
                    n12 -> n17 [label="pattern success"]
                    n13 -> n18
                    n14 -> n19
                    n16 -> n20
                    n17 -> n21
                    n18 -> n22
                    n20 -> n23
                    n21 -> n24
                    n23 -> n25
                    n15 -> n26
                    n19 -> n26
                    n22 -> n26
                    n24 -> n26
                    n25 -> n26
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 5)
    }

    func testExpression_switch_emptyCases() {
        let stmt: CompoundStatement = [
            Statement.switch(
                .identifier("a"),
                cases: [
                    SwitchCase(patterns: [.identifier("b")], statements: []),
                    SwitchCase(patterns: [.identifier("c")], statements: []),
                    SwitchCase(patterns: [.identifier("d")], statements: []),
                ],
                defaultStatements: []
            )
        ]
        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{exp}"]
                    n4 [label="a"]
                    n5 [label="SwitchExpression"]
                    n6 [label="{case b}"]
                    n7 [label="{case c}"]
                    n8 [label="{compound}"]
                    n9 [label="{case d}"]
                    n10 [label="{compound}"]
                    n11 [label="{default}"]
                    n12 [label="{compound}"]
                    n13 [label="{compound}"]
                    n14 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7 [label="pattern fail"]
                    n6 -> n8 [label="pattern success"]
                    n7 -> n9 [label="pattern fail"]
                    n7 -> n10 [label="pattern success"]
                    n9 -> n11 [label="pattern fail"]
                    n9 -> n12 [label="pattern success"]
                    n11 -> n13
                    n8 -> n14
                    n10 -> n14
                    n12 -> n14
                    n13 -> n14
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 4)
    }

    func testExpression_switch_emptyCasesWithFallthrough() {
        let stmt: CompoundStatement = [
            Statement.switch(
                .identifier("a"),
                cases: [
                    SwitchCase(
                        patterns: [.identifier("b")],
                        statements: [
                            .fallthrough
                        ]
                    ),
                    SwitchCase(patterns: [.identifier("c")], statements: []),
                    SwitchCase(patterns: [.identifier("d")], statements: []),
                ],
                defaultStatements: []
            )
        ]
        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{exp}"]
                    n4 [label="a"]
                    n5 [label="SwitchExpression"]
                    n6 [label="{case b}"]
                    n7 [label="{compound}"]
                    n8 [label="{case c}"]
                    n9 [label="{case d}"]
                    n10 [label="{fallthrough}"]
                    n11 [label="{compound}"]
                    n12 [label="{default}"]
                    n13 [label="{compound}"]
                    n14 [label="{compound}"]
                    n15 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7 [label="pattern success"]
                    n6 -> n8 [label="pattern fail"]
                    n8 -> n9 [label="pattern fail"]
                    n7 -> n10
                    n8 -> n11 [label="pattern success"]
                    n10 -> n11 [label="fallthrough"]
                    n9 -> n12 [label="pattern fail"]
                    n9 -> n13 [label="pattern success"]
                    n12 -> n14
                    n11 -> n15
                    n13 -> n15
                    n14 -> n15
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 3)
    }

    func testExpression_switch_casesWithExpressionPatterns() {
        let stmt: CompoundStatement = #ast_expandStatements({ (a: Int, b: Int) in
            switch a {
            case b:
                break
            case b + b:
                break
            default:
                break
            }
        })
        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{exp}"]
                    n4 [label="a"]
                    n5 [label="SwitchExpression"]
                    n6 [label="{case b}"]
                    n7 [label="b"]
                    n8 [label="{case b + b}"]
                    n9 [label="{compound}"]
                    n10 [label="b"]
                    n11 [label="{break}"]
                    n12 [label="b"]
                    n13 [label="b + b"]
                    n14 [label="{default}"]
                    n15 [label="{compound}"]
                    n16 [label="{compound}"]
                    n17 [label="{break}"]
                    n18 [label="{break}"]
                    n19 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8 [label="pattern fail"]
                    n7 -> n9 [label="pattern success"]
                    n8 -> n10
                    n9 -> n11
                    n10 -> n12
                    n12 -> n13
                    n13 -> n14 [label="pattern fail"]
                    n13 -> n15 [label="pattern success"]
                    n14 -> n16
                    n15 -> n17
                    n16 -> n18
                    n11 -> n19
                    n17 -> n19
                    n18 -> n19
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 3)
    }

    func testExpression_switch_casesWithWherePattern() {
        let stmt: CompoundStatement = [
            Statement.switch(
                .identifier("switchExp"),
                cases: [
                    SwitchCase(
                        casePatterns: [
                            .init(
                                pattern: .identifier("patternA"),
                                whereClause: .identifier("whereClauseA")
                            ),
                        ],
                        body: [
                            .expression(.identifier("case1")),
                        ]
                    ),
                    SwitchCase(
                        patterns: [
                            .identifier("patternB"),
                        ],
                        statements: [
                            .expression(.identifier("case2")),
                        ]
                    ),
                ],
                default: nil
            )
        ]
        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{exp}"]
                    n4 [label="switchExp"]
                    n5 [label="SwitchExpression"]
                    n6 [label="{case patternA where whereClauseA}"]
                    n7 [label="whereClauseA"]
                    n8 [label="{case patternB}"]
                    n9 [label="{compound}"]
                    n10 [label="{compound}"]
                    n11 [label="{exp}"]
                    n12 [label="{exp}"]
                    n13 [label="case1"]
                    n14 [label="case2"]
                    n15 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n6 -> n8 [label="pattern fail"]
                    n7 -> n8 [label="pattern fail"]
                    n7 -> n9 [label="pattern success"]
                    n8 -> n10 [label="pattern success"]
                    n9 -> n11
                    n10 -> n12
                    n11 -> n13
                    n12 -> n14
                    n13 -> n15
                    n14 -> n15
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testExpression_switch_casesWithMultiplePatterns_withWherePattern() {
        let stmt: CompoundStatement = [
            Statement.switch(
                .identifier("switchExp"),
                cases: [
                    SwitchCase(
                        casePatterns: [
                            .init(
                                pattern: .identifier("patternA"),
                                whereClause: .identifier("whereClauseA")
                            ),
                            .init(
                                pattern: .expression(.identifier("expressionB")),
                                whereClause: .identifier("whereClauseB")
                            ),
                            .init(
                                pattern: .identifier("patternC")
                            ),
                            .init(
                                pattern: .identifier("patternD"),
                                whereClause: .identifier("whereClauseD")
                            ),
                        ],
                        body: [
                            .expression(.identifier("case1")),
                        ]
                    ),
                    SwitchCase(
                        patterns: [
                            .identifier("patternB"),
                        ],
                        statements: [
                            .expression(.identifier("case2")),
                        ]
                    ),
                ],
                default: nil
            )
        ]
        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{exp}"]
                    n4 [label="switchExp"]
                    n5 [label="SwitchExpression"]
                    n6 [label="{case [patternA where whereClauseA, expressionB where whereClauseB, patternC, patternD where whereClauseD]}"]
                    n7 [label="whereClauseA"]
                    n8 [label="{case patternB}"]
                    n9 [label="expressionB"]
                    n10 [label="{compound}"]
                    n11 [label="whereClauseB"]
                    n12 [label="{exp}"]
                    n13 [label="whereClauseD"]
                    n14 [label="case2"]
                    n15 [label="{compound}"]
                    n16 [label="{exp}"]
                    n17 [label="case1"]
                    n18 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n6 -> n8 [label="pattern fail"]
                    n7 -> n8 [label="pattern fail"]
                    n9 -> n8 [label="pattern fail"]
                    n11 -> n8 [label="pattern fail"]
                    n13 -> n8 [label="pattern fail"]
                    n7 -> n9
                    n8 -> n10 [label="pattern success"]
                    n9 -> n11
                    n10 -> n12
                    n11 -> n13
                    n12 -> n14
                    n13 -> n15 [label="pattern success"]
                    n15 -> n16
                    n16 -> n17
                    n14 -> n18
                    n17 -> n18
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testExpression_switch_casesWithMultiplePatterns_withWherePattern_withThrowingExpressionPattern() {
        let stmt: CompoundStatement = [
            Statement.switch(
                .identifier("switchExp"),
                cases: [
                    SwitchCase(
                        casePatterns: [
                            .init(
                                pattern: .identifier("patternA"),
                                whereClause: .identifier("whereClauseA")
                            ),
                            .init(
                                pattern: .expression(.try(.identifier("expressionB"))),
                                whereClause: .identifier("whereClauseB")
                            ),
                            .init(
                                pattern: .identifier("patternC")
                            ),
                            .init(
                                pattern: .identifier("patternD"),
                                whereClause: .identifier("whereClauseD")
                            ),
                        ],
                        body: [
                            .expression(.identifier("case1")),
                        ]
                    ),
                    SwitchCase(
                        patterns: [
                            .identifier("patternB"),
                        ],
                        statements: [
                            .expression(.identifier("case2")),
                        ]
                    ),
                ],
                default: nil
            )
        ]
        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{exp}"]
                    n4 [label="switchExp"]
                    n5 [label="SwitchExpression"]
                    n6 [label="{case [patternA where whereClauseA, try expressionB where whereClauseB, patternC, patternD where whereClauseD]}"]
                    n7 [label="{case patternB}"]
                    n8 [label="whereClauseA"]
                    n9 [label="{compound}"]
                    n10 [label="expressionB"]
                    n11 [label="{exp}"]
                    n12 [label="try expressionB"]
                    n13 [label="whereClauseB"]
                    n14 [label="case2"]
                    n15 [label="whereClauseD"]
                    n16 [label="{compound}"]
                    n17 [label="{exp}"]
                    n18 [label="case1"]
                    n19 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7 [label="pattern fail"]
                    n8 -> n7 [label="pattern fail"]
                    n12 -> n7 [label="pattern fail"]
                    n13 -> n7 [label="pattern fail"]
                    n15 -> n7 [label="pattern fail"]
                    n6 -> n8
                    n7 -> n9 [label="pattern success"]
                    n8 -> n10
                    n9 -> n11
                    n10 -> n12
                    n12 -> n13
                    n11 -> n14
                    n13 -> n15
                    n15 -> n16 [label="pattern success"]
                    n16 -> n17
                    n17 -> n18
                    n12 -> n19 [label="throws"]
                    n14 -> n19
                    n18 -> n19
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 3)
    }

    func testExpression_switch_fallthrough() {
        let stmt: CompoundStatement = [
            Statement.switch(
                .identifier("switchExp"),
                cases: [
                    SwitchCase(
                        patterns: [
                            .identifier("caseA"),
                        ],
                        statements: [
                            .expression(.identifier("b")),
                            .fallthrough,
                        ]
                    ),
                    SwitchCase(
                        patterns: [
                            .identifier("caseB"),
                        ],
                        statements: [
                            .expression(.identifier("c"))
                        ]
                    ),
                ],
                defaultStatements: [
                    .expression(.identifier("defaultExp"))
                ]
            )
        ]
        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{exp}"]
                    n4 [label="switchExp"]
                    n5 [label="SwitchExpression"]
                    n6 [label="{case caseA}"]
                    n7 [label="{compound}"]
                    n8 [label="{case caseB}"]
                    n9 [label="{exp}"]
                    n10 [label="{default}"]
                    n11 [label="{compound}"]
                    n12 [label="b"]
                    n13 [label="{compound}"]
                    n14 [label="{exp}"]
                    n15 [label="{fallthrough}"]
                    n16 [label="{exp}"]
                    n17 [label="c"]
                    n18 [label="defaultExp"]
                    n19 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7 [label="pattern success"]
                    n6 -> n8 [label="pattern fail"]
                    n7 -> n9
                    n8 -> n10 [label="pattern fail"]
                    n8 -> n11 [label="pattern success"]
                    n15 -> n11 [label="fallthrough"]
                    n9 -> n12
                    n10 -> n13
                    n11 -> n14
                    n12 -> n15
                    n13 -> n16
                    n14 -> n17
                    n16 -> n18
                    n17 -> n19
                    n18 -> n19
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testExpression_switch_fallthrough_emptyCases() {
        let stmt: CompoundStatement = [
            Statement.switch(
                .identifier("switchExp"),
                cases: [
                    SwitchCase(
                        patterns: [],
                        statements: [
                            .expression(.identifier("b")),
                            .fallthrough,
                        ]
                    ),
                    SwitchCase(
                        patterns: [],
                        statements: [
                            .expression(.identifier("c"))
                        ]
                    ),
                ],
                defaultStatements: [
                    .expression(.identifier("defaultExp"))
                ]
            )
        ]
        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph, expectsUnreachable: true)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{exp}"]
                    n4 [label="switchExp"]
                    n5 [label="SwitchExpression"]
                    n6 [label="{case []}"]
                    n7 [label="{compound}"]
                    n8 [label="{exp}"]
                    n9 [label="b"]
                    n10 [label="{fallthrough}"]
                    n11 [label="{compound}"]
                    n12 [label="{exp}"]
                    n13 [label="c"]
                    n14 [label="{case []}"]
                    n15 [label="{default}"]
                    n16 [label="{compound}"]
                    n17 [label="{exp}"]
                    n18 [label="defaultExp"]
                    n19 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7 [label="pattern success"]
                    n7 -> n8
                    n8 -> n9
                    n9 -> n10
                    n10 -> n11 [label="fallthrough"]
                    n14 -> n11 [label="pattern success"]
                    n11 -> n12
                    n12 -> n13
                    n15 -> n16
                    n16 -> n17
                    n17 -> n18
                    n13 -> n19
                    n18 -> n19
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testExpression_switch_breakDefer() {
        let stmt: CompoundStatement = [
            Statement.switch(
                .identifier("switchExp"),
                cases: [
                    SwitchCase(
                        patterns: [
                            .identifier("caseA"),
                        ],
                        statements: [
                            .expression(.identifier("b")),
                            .defer([
                                .expression(.identifier("c"))
                            ]),
                            Statement.if(
                                .identifier("predicate"),
                                body: [
                                    .break()
                                ]
                            ),
                            .expression(.identifier("d")),
                        ]
                    )
                ],
                defaultStatements: [
                    .expression(.identifier("defaultExp"))
                ]
            )
        ]
        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{exp}"]
                    n4 [label="switchExp"]
                    n5 [label="SwitchExpression"]
                    n6 [label="{case caseA}"]
                    n7 [label="{compound}"]
                    n8 [label="{default}"]
                    n9 [label="{exp}"]
                    n10 [label="{compound}"]
                    n11 [label="b"]
                    n12 [label="{exp}"]
                    n13 [label="{exp}"]
                    n14 [label="defaultExp"]
                    n15 [label="{if}"]
                    n16 [label="predicate"]
                    n17 [label="{if predicate}"]
                    n18 [label="{compound}"]
                    n19 [label="{exp}"]
                    n20 [label="d"]
                    n21 [label="{break}"]
                    n22 [label="{defer}"]
                    n23 [label="{defer}"]
                    n24 [label="{compound}"]
                    n25 [label="{compound}"]
                    n26 [label="{exp}"]
                    n27 [label="{exp}"]
                    n28 [label="c"]
                    n29 [label="c"]
                    n30 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7 [label="pattern success"]
                    n6 -> n8 [label="pattern fail"]
                    n7 -> n9
                    n8 -> n10
                    n9 -> n11
                    n10 -> n12
                    n11 -> n13
                    n12 -> n14
                    n13 -> n15
                    n15 -> n16
                    n16 -> n17
                    n17 -> n18 [label="true"]
                    n17 -> n19 [label="false"]
                    n19 -> n20
                    n18 -> n21
                    n20 -> n22
                    n21 -> n23
                    n22 -> n24
                    n23 -> n25
                    n24 -> n26
                    n25 -> n27
                    n26 -> n28
                    n27 -> n29
                    n14 -> n30
                    n28 -> n30
                    n29 -> n30
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 3)
    }

    func testExpression_switch_fallthroughWithDefer() {
        /*
        switch switchExp {
        case b:
            c

            defer {
                d
            }

            if predicateFallthrough {
                fallthrough
            }

            e

            defer {
                deferredExp
            }

        case f:
            g

        default:
            defaultExp
        }
        */
        let stmt: CompoundStatement = [
            Statement.switch(
                .identifier("switchExp"),
                cases: [
                    SwitchCase(
                        patterns: [.identifier("b")],
                        statements: [
                            .expression(.identifier("c")),
                            .defer([
                                .expression(.identifier("d"))
                            ]),
                            Statement.if(
                                .identifier("predicateFallthrough"),
                                body: [
                                    .fallthrough
                                ]
                            ),
                            .expression(.identifier("e")),
                            .defer([
                                .expression(.identifier("deferredExp"))
                            ]),
                        ]
                    ),
                    SwitchCase(
                        patterns: [.identifier("f")],
                        statements: [
                            .expression(.identifier("g"))
                        ]
                    ),
                ],
                defaultStatements: [
                    .expression(.identifier("defaultExp"))
                ]
            )
        ]
        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{exp}"]
                    n4 [label="switchExp"]
                    n5 [label="SwitchExpression"]
                    n6 [label="{case b}"]
                    n7 [label="{compound}"]
                    n8 [label="{case f}"]
                    n9 [label="{exp}"]
                    n10 [label="{default}"]
                    n11 [label="{compound}"]
                    n12 [label="c"]
                    n13 [label="{compound}"]
                    n14 [label="{exp}"]
                    n15 [label="{exp}"]
                    n16 [label="{exp}"]
                    n17 [label="g"]
                    n18 [label="{if}"]
                    n19 [label="defaultExp"]
                    n20 [label="predicateFallthrough"]
                    n21 [label="{if predicateFallthrough}"]
                    n22 [label="{compound}"]
                    n23 [label="{exp}"]
                    n24 [label="{fallthrough}"]
                    n25 [label="e"]
                    n26 [label="{defer}"]
                    n27 [label="{defer}"]
                    n28 [label="{compound}"]
                    n29 [label="{compound}"]
                    n30 [label="{exp}"]
                    n31 [label="{exp}"]
                    n32 [label="deferredExp"]
                    n33 [label="deferredExp"]
                    n34 [label="{defer}"]
                    n35 [label="{defer}"]
                    n36 [label="{compound}"]
                    n37 [label="{compound}"]
                    n38 [label="{exp}"]
                    n39 [label="{exp}"]
                    n40 [label="d"]
                    n41 [label="d"]
                    n42 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7 [label="pattern success"]
                    n6 -> n8 [label="pattern fail"]
                    n7 -> n9
                    n8 -> n10 [label="pattern fail"]
                    n8 -> n11 [label="pattern success"]
                    n40 -> n11 [label="fallthrough"]
                    n9 -> n12
                    n10 -> n13
                    n11 -> n14
                    n12 -> n15
                    n13 -> n16
                    n14 -> n17
                    n15 -> n18
                    n16 -> n19
                    n18 -> n20
                    n20 -> n21
                    n21 -> n22 [label="true"]
                    n21 -> n23 [label="false"]
                    n22 -> n24
                    n23 -> n25
                    n24 -> n26
                    n25 -> n27
                    n26 -> n28
                    n27 -> n29
                    n28 -> n30
                    n29 -> n31
                    n30 -> n32
                    n31 -> n33
                    n32 -> n34
                    n33 -> n35
                    n34 -> n36
                    n35 -> n37
                    n36 -> n38
                    n37 -> n39
                    n38 -> n40
                    n39 -> n41
                    n17 -> n42
                    n19 -> n42
                    n41 -> n42
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 3)
    }

    func testExpression_switch_fallthroughWithDeferInterwovenWithReturn() {
        let stmt: CompoundStatement = [
            Statement.switch(
                .identifier("switchExp"),
                cases: [
                    SwitchCase(
                        patterns: [
                            .identifier("caseA"),
                        ],
                        statements: [
                            .expression(.identifier("b")),
                            .defer([
                                .expression(.identifier("deferredExp"))
                            ]),
                            Statement.if(
                                .identifier("predicateFallthrough"),
                                body: [
                                    .expression(.identifier("d")),
                                    .fallthrough,
                                ]
                            ),
                            .expression(.identifier("e")),
                            Statement.if(
                                .identifier("predicateReturn"),
                                body: [
                                    .return(nil)
                                ]
                            ),
                            .defer([
                                .expression(.identifier("f"))
                            ]),
                        ]
                    ),
                    SwitchCase(
                        patterns: [
                            .identifier("caseB"),
                        ],
                        statements: [
                            .expression(.identifier("g"))
                        ]
                    ),
                ],
                defaultStatements: [
                    .expression(.identifier("defaultExp"))
                ]
            )
        ]
        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{exp}"]
                    n4 [label="switchExp"]
                    n5 [label="SwitchExpression"]
                    n6 [label="{case caseA}"]
                    n7 [label="{compound}"]
                    n8 [label="{case caseB}"]
                    n9 [label="{exp}"]
                    n10 [label="{default}"]
                    n11 [label="{compound}"]
                    n12 [label="b"]
                    n13 [label="{compound}"]
                    n14 [label="{exp}"]
                    n15 [label="{exp}"]
                    n16 [label="{exp}"]
                    n17 [label="g"]
                    n18 [label="{if}"]
                    n19 [label="defaultExp"]
                    n20 [label="predicateFallthrough"]
                    n21 [label="{if predicateFallthrough}"]
                    n22 [label="{compound}"]
                    n23 [label="{exp}"]
                    n24 [label="{exp}"]
                    n25 [label="e"]
                    n26 [label="d"]
                    n27 [label="{exp}"]
                    n28 [label="{fallthrough}"]
                    n29 [label="{if}"]
                    n30 [label="{defer}"]
                    n31 [label="predicateReturn"]
                    n32 [label="{compound}"]
                    n33 [label="{if predicateReturn}"]
                    n34 [label="{compound}"]
                    n35 [label="{exp}"]
                    n36 [label="{defer}"]
                    n37 [label="{return}"]
                    n38 [label="f"]
                    n39 [label="{compound}"]
                    n40 [label="{defer}"]
                    n41 [label="{defer}"]
                    n42 [label="{exp}"]
                    n43 [label="{compound}"]
                    n44 [label="{compound}"]
                    n45 [label="f"]
                    n46 [label="{exp}"]
                    n47 [label="{exp}"]
                    n48 [label="{defer}"]
                    n49 [label="f"]
                    n50 [label="deferredExp"]
                    n51 [label="{compound}"]
                    n52 [label="{defer}"]
                    n53 [label="{exp}"]
                    n54 [label="{compound}"]
                    n55 [label="deferredExp"]
                    n56 [label="{exp}"]
                    n57 [label="deferredExp"]
                    n58 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7 [label="pattern success"]
                    n6 -> n8 [label="pattern fail"]
                    n7 -> n9
                    n8 -> n10 [label="pattern fail"]
                    n8 -> n11 [label="pattern success"]
                    n50 -> n11 [label="fallthrough"]
                    n9 -> n12
                    n10 -> n13
                    n11 -> n14
                    n12 -> n15
                    n13 -> n16
                    n14 -> n17
                    n15 -> n18
                    n16 -> n19
                    n18 -> n20
                    n20 -> n21
                    n21 -> n22 [label="true"]
                    n21 -> n23 [label="false"]
                    n22 -> n24
                    n23 -> n25
                    n24 -> n26
                    n25 -> n27
                    n26 -> n28
                    n27 -> n29
                    n28 -> n30
                    n29 -> n31
                    n30 -> n32
                    n31 -> n33
                    n33 -> n34 [label="true"]
                    n32 -> n35
                    n33 -> n36 [label="false"]
                    n34 -> n37
                    n35 -> n38
                    n36 -> n39
                    n37 -> n40
                    n38 -> n41
                    n39 -> n42
                    n40 -> n43
                    n41 -> n44
                    n42 -> n45
                    n43 -> n46
                    n44 -> n47
                    n45 -> n48
                    n46 -> n49
                    n47 -> n50
                    n48 -> n51
                    n49 -> n52
                    n51 -> n53
                    n52 -> n54
                    n53 -> n55
                    n54 -> n56
                    n56 -> n57
                    n17 -> n58
                    n19 -> n58
                    n55 -> n58
                    n57 -> n58
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 4)
    }

    func testExpression_switch_asExpression_assignment() {
        let exp = #ast_expandExpression(firstExpressionIn: { (a: inout Int) in
            a = switch a {
                case 0: 0
                case 1: 1
                default: 2
                }
        })
        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="a"]
                    n4 [label="SwitchExpression"]
                    n5 [label="{case 0}"]
                    n6 [label="0"]
                    n7 [label="{case 1}"]
                    n8 [label="{compound}"]
                    n9 [label="1"]
                    n10 [label="{exp}"]
                    n11 [label="{default}"]
                    n12 [label="{compound}"]
                    n13 [label="0"]
                    n14 [label="{compound}"]
                    n15 [label="{exp}"]
                    n16 [label="a = SwitchExpression"]
                    n17 [label="{exp}"]
                    n18 [label="1"]
                    n19 [label="2"]
                    n20 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7 [label="pattern fail"]
                    n6 -> n8 [label="pattern success"]
                    n7 -> n9
                    n8 -> n10
                    n9 -> n11 [label="pattern fail"]
                    n9 -> n12 [label="pattern success"]
                    n10 -> n13
                    n11 -> n14
                    n12 -> n15
                    n13 -> n16
                    n18 -> n16
                    n19 -> n16
                    n14 -> n17
                    n15 -> n18
                    n17 -> n19
                    n16 -> n20
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpression_unknown() {
        let exp: SwiftAST.Expression =
            .unknown(.init(context: "a"))

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func tesShortCircuit_andOperand() {
        let exp: SwiftAST.Expression =
            .identifier("a").binary(op: .and, rhs: .identifier("b"))

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{exp}"]
                    n3 [label="a"]
                    n4 [label="b"]
                    n5 [label="a && b"]
                    n6 [label="exit"]
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n3 -> n5
                    n4 -> n5
                    n5 -> n6
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testShortCircuit_orOperand() {
        let exp: SwiftAST.Expression =
            .identifier("a").binary(op: .or, rhs: .identifier("b"))

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="b"]
                    n4 [label="a || b"]
                    n5 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n2 -> n4
                    n3 -> n4
                    n4 -> n5
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testShortCircuit_nullCoalesceOperand() {
        let exp: SwiftAST.Expression =
            .identifier("a").binary(op: .nullCoalesce, rhs: .identifier("b"))

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="b"]
                    n4 [label="a ?? b"]
                    n5 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n2 -> n4
                    n3 -> n4
                    n4 -> n5
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testShortCircuit_nestedExpression() {
        let exp: SwiftAST.Expression =
            .arrayLiteral([
                .identifier("a").binary(op: .and, rhs: .identifier("b")),
                .identifier("c"),
            ])

        let graph = ControlFlowGraph.forExpression(exp)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="a"]
                    n3 [label="b"]
                    n4 [label="a && b"]
                    n5 [label="c"]
                    n6 [label="[a && b, c]"]
                    n7 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n2 -> n4
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                }
                """
        )
        XCTAssert(graph.entry.node === exp)
        XCTAssert(graph.exit.node === exp)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    #if false // For testing behavior of Swift expression control flow

    func testThing() {
        func returnsState(line: UInt = #line, column: UInt = #column) -> State {
            print(#function, line, column)
            return State()
        }

        func returnsMaybeState(_ value: State?, line: UInt = #line, column: UInt = #column) -> State? {
            print(#function, line, column)
            return value
        }

        func sideEffect(label: String, result: Bool = true, line: UInt = #line, column: UInt = #column) -> Int {
            print(#function, line, column)
            return 0
        }

        print(returnsState().state[returnsState()].field)
    }

    private class State: Hashable {
        var field: Int = 0
        var state: State {
            return self
        }

        subscript(value: State) -> State {
            return self
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(self))
        }

        static func == (lhs: State, rhs: State) -> Bool {
            lhs === rhs
        }
    }

    #endif
}
