import XCTest

@testable import SwiftAST
@testable import SwiftCFG

class ControlFlowGraph_CreationStmtTests: XCTestCase {
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

    func testExpression() {
        let stmt: CompoundStatement = [
            .expression(.identifier("exp"))
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
                    n4 [label="exp"]
                    n5 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testExpressions() {
        let stmt: CompoundStatement = [
            .expression(.identifier("exp1")),
            .expression(.identifier("exp2")),
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
                    n4 [label="exp1"]
                    n5 [label="{exp}"]
                    n6 [label="exp2"]
                    n7 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testVariableDeclaration() {
        let stmt: CompoundStatement = [
            .variableDeclaration(identifier: "v1", type: .int, initialization: nil),
            .variableDeclaration(identifier: "v2", type: .int, initialization: nil),
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="var v1: Int"]
                    n4 [label="v1: Int"]
                    n5 [label="var v2: Int"]
                    n6 [label="v2: Int"]
                    n7 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testVariableDeclaration_multipleDeclarations() {
        let stmt: CompoundStatement = [
            .variableDeclarations([
                .init(identifier: "v1", type: .int, initialization: .identifier("a")),
                .init(identifier: "v2", type: .int, initialization: .identifier("b")),
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
                    n3 [label="var v1: Int, var v2: Int"]
                    n4 [label="a"]
                    n5 [label="v1: Int = a"]
                    n6 [label="b"]
                    n7 [label="v2: Int = b"]
                    n8 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testVariableDeclaration_initialization() {
        let stmt: CompoundStatement = [
            .variableDeclaration(identifier: "v1", type: .int, initialization: .identifier("a")),
            .variableDeclaration(identifier: "v2", type: .int, initialization: nil),
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="var v1: Int"]
                    n4 [label="a"]
                    n5 [label="v1: Int = a"]
                    n6 [label="var v2: Int"]
                    n7 [label="v2: Int"]
                    n8 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testDoStatement() {
        let stmt: CompoundStatement = [
            Statement.do([
                .expression(
                    .identifier("exp")
                )
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
                    n6 [label="exp"]
                    n7 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testDoStatement_labeledBreak() {
        let stmt: CompoundStatement = [
            .while(.identifier("predicate"), body: [
                Statement.do([
                    .expression(.identifier("a")),
                    .break(targetLabel: "doLabel"),
                    .expression(.identifier("b")),
                ]).labeled("doLabel"),
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
                    n4 [label="predicate"]
                    n5 [label="{if predicate}"]
                    n6 [label="{compound}"]
                    n7 [label="{do}"]
                    n8 [label="{compound}"]
                    n9 [label="{exp}"]
                    n10 [label="a"]
                    n11 [label="{break doLabel}"]
                    n12 [label="{exp}"]
                    n13 [label="b"]
                    n14 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n11 -> n3 [color="#aa3333", penwidth=0.5]
                    n13 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6 [label="true"]
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9
                    n9 -> n10
                    n10 -> n11
                    n12 -> n13
                    n5 -> n14 [label="false"]
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testDoStatement_catchErrorFlow() {
        let stmt: CompoundStatement = [
            .expression(.identifier("preDo")),
            .do([
                .expression(.identifier("preError")),
                .throw(.identifier("Error")),
                .expression(.identifier("postError")),
            ]).catch([
                .expression(.identifier("errorHandler")),
            ]),
            .expression(.identifier("end")),
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
                    n4 [label="preDo"]
                    n5 [label="{do}"]
                    n6 [label="{compound}"]
                    n7 [label="{exp}"]
                    n8 [label="preError"]
                    n9 [label="Error"]
                    n10 [label="{throw Error}"]
                    n11 [label="{catch}"]
                    n12 [label="{compound}"]
                    n13 [label="{exp}"]
                    n14 [label="errorHandler"]
                    n15 [label="{exp}"]
                    n16 [label="end"]
                    n17 [label="{exp}"]
                    n18 [label="postError"]
                    n19 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9
                    n9 -> n10
                    n10 -> n11
                    n11 -> n12
                    n12 -> n13
                    n13 -> n14
                    n14 -> n15
                    n18 -> n15
                    n15 -> n16
                    n17 -> n18
                    n16 -> n19
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testDoStatement_catchConditionalErrorFlow() {
        let stmt: CompoundStatement = [
            .do([
                .expression(.identifier("preError")),
                .if(.identifier("a"), body: [
                    .throw(.identifier("Error")),
                ]),
                .expression(.identifier("postError")),
            ]).catch([
                .expression(.identifier("errorHandler")),
            ]),
            .expression(.identifier("end")),
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
                    n6 [label="preError"]
                    n7 [label="{exp}"]
                    n8 [label="{if}"]
                    n9 [label="a"]
                    n10 [label="{if a}"]
                    n11 [label="{compound}"]
                    n12 [label="{exp}"]
                    n13 [label="Error"]
                    n14 [label="postError"]
                    n15 [label="{throw Error}"]
                    n16 [label="{exp}"]
                    n17 [label="{catch}"]
                    n18 [label="end"]
                    n19 [label="{compound}"]
                    n20 [label="{exp}"]
                    n21 [label="errorHandler"]
                    n22 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9
                    n9 -> n10
                    n10 -> n11 [label="true"]
                    n10 -> n12 [label="false"]
                    n11 -> n13
                    n12 -> n14
                    n13 -> n15
                    n14 -> n16
                    n21 -> n16
                    n15 -> n17
                    n16 -> n18
                    n17 -> n19
                    n19 -> n20
                    n20 -> n21
                    n18 -> n22
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testDoStatement_catchNestedErrorFlow() {
        let stmt: CompoundStatement = [
            .expression(.identifier("preDo")),
            .do([
                .expression(.identifier("preError")),
                .do([
                    .throw(.identifier("Error")),
                ]),
                .expression(.identifier("postError")),
            ]).catch([
                .expression(.identifier("errorHandler")),
            ]),
            .expression(.identifier("end")),
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
                    n4 [label="preDo"]
                    n5 [label="{do}"]
                    n6 [label="{compound}"]
                    n7 [label="{exp}"]
                    n8 [label="preError"]
                    n9 [label="{do}"]
                    n10 [label="{compound}"]
                    n11 [label="Error"]
                    n12 [label="{throw Error}"]
                    n13 [label="{catch}"]
                    n14 [label="{compound}"]
                    n15 [label="{exp}"]
                    n16 [label="errorHandler"]
                    n17 [label="{exp}"]
                    n18 [label="end"]
                    n19 [label="{exp}"]
                    n20 [label="postError"]
                    n21 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9
                    n9 -> n10
                    n10 -> n11
                    n11 -> n12
                    n12 -> n13
                    n13 -> n14
                    n14 -> n15
                    n15 -> n16
                    n16 -> n17
                    n20 -> n17
                    n17 -> n18
                    n19 -> n20
                    n18 -> n21
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testDoStatement_multipleCatchFlow() {
        // TODO: Support catch skipping depending on catch block's pattern.

        let stmt: CompoundStatement = [
            .expression(.identifier("preDo")),
            .do([
                .expression(.identifier("preError")),
                .throw(.identifier("Error")),
                .expression(.identifier("postError")),
            ]).catch(pattern: .identifier("a"), [
                .expression(.identifier("errorHandler 1")),
            ]).catch([
                .expression(.identifier("errorHandler 2")),
            ]),
            .expression(.identifier("end")),
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
                    n4 [label="preDo"]
                    n5 [label="{do}"]
                    n6 [label="{compound}"]
                    n7 [label="{exp}"]
                    n8 [label="preError"]
                    n9 [label="Error"]
                    n10 [label="{throw Error}"]
                    n11 [label="{catch a}"]
                    n12 [label="{compound}"]
                    n13 [label="{exp}"]
                    n14 [label="errorHandler 1"]
                    n15 [label="{exp}"]
                    n16 [label="end"]
                    n17 [label="{catch}"]
                    n18 [label="{compound}"]
                    n19 [label="{exp}"]
                    n20 [label="{exp}"]
                    n21 [label="errorHandler 2"]
                    n22 [label="postError"]
                    n23 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9
                    n9 -> n10
                    n10 -> n11
                    n11 -> n12
                    n12 -> n13
                    n13 -> n14
                    n14 -> n15
                    n21 -> n15
                    n22 -> n15
                    n15 -> n16
                    n17 -> n18
                    n18 -> n20
                    n20 -> n21
                    n19 -> n22
                    n16 -> n23
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testDoStatement_catchWithNoError() {
        let stmt: CompoundStatement = [
            .do([
                .expression(.identifier("a")),
            ]).catch([
                .expression(.identifier("b")),
            ]),
            .expression(.identifier("c")),
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
                    n7 [label="{exp}"]
                    n8 [label="c"]
                    n9 [label="{catch}"]
                    n10 [label="{compound}"]
                    n11 [label="{exp}"]
                    n12 [label="b"]
                    n13 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n12 -> n7
                    n7 -> n8
                    n9 -> n10
                    n10 -> n11
                    n11 -> n12
                    n8 -> n13
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testGuard() {
        let stmt: CompoundStatement = [
            Statement.guard(
                .identifier("predicate"),
                else: [
                    .expression(.identifier("guardBody")),
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
                    n3 [label="{guard}"]
                    n4 [label="predicate"]
                    n5 [label="{if predicate}"]
                    n6 [label="{compound}"]
                    n7 [label="{exp}"]
                    n8 [label="guardBody"]
                    n9 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6 [label="false"]
                    n6 -> n7
                    n7 -> n8
                    n5 -> n9 [label="true"]
                    n8 -> n9
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testGuard_controlFlowBreak() {
        let stmt: CompoundStatement = [
            Statement.guard(
                .identifier("predicate"),
                else: [
                    .expression(.identifier("guardBody")),
                    .return(nil),
                ]
            ),
            Statement.expression(.identifier("postGuard"))
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{guard}"]
                    n4 [label="predicate"]
                    n5 [label="{if predicate}"]
                    n6 [label="{compound}"]
                    n7 [label="{exp}"]
                    n8 [label="{exp}"]
                    n9 [label="postGuard"]
                    n10 [label="guardBody"]
                    n11 [label="{return}"]
                    n12 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6 [label="false"]
                    n5 -> n7 [label="true"]
                    n6 -> n8
                    n7 -> n9
                    n8 -> n10
                    n10 -> n11
                    n9 -> n12
                    n11 -> n12
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testGuard_multiClause() {
        let stmt: CompoundStatement = [
            Statement.guard(
                clauses: [
                    .init(expression: .identifier("predicate1")),
                    .init(expression: .identifier("predicate2")),
                ],
                else: [
                    .expression(.identifier("guardBody")),
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
                    n3 [label="{guard}"]
                    n4 [label="predicate1"]
                    n5 [label="{if predicate1}"]
                    n6 [label="{compound}"]
                    n7 [label="predicate2"]
                    n8 [label="{exp}"]
                    n9 [label="{if predicate2}"]
                    n10 [label="guardBody"]
                    n11 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6 [label="false"]
                    n9 -> n6 [label="false"]
                    n5 -> n7 [label="true"]
                    n6 -> n8
                    n7 -> n9
                    n8 -> n10
                    n9 -> n11 [label="true"]
                    n10 -> n11
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testWhileLoop() {
        let stmt: CompoundStatement = [
            Statement.while(
                .identifier("predicate"),
                body: [
                    .expression(.identifier("loopBody"))
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
                    n3 [label="{while}"]
                    n4 [label="predicate"]
                    n5 [label="{if predicate}"]
                    n6 [label="{compound}"]
                    n7 [label="{exp}"]
                    n8 [label="loopBody"]
                    n9 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n8 -> n3 [color="#aa3333", penwidth=0.5]
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6 [label="true"]
                    n6 -> n7
                    n7 -> n8
                    n5 -> n9 [label="false"]
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testWhileLoop_empty() {
        let stmt: CompoundStatement = [
            Statement.while(
                .identifier("predicate"),
                body: []
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
                    n3 [label="{while}"]
                    n4 [label="predicate"]
                    n5 [label="{if predicate}"]
                    n6 [label="{compound}"]
                    n7 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n6 -> n3 [color="#aa3333", penwidth=0.5]
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6 [label="true"]
                    n5 -> n7 [label="false"]
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testWhileLoop_labeledContinue() {
        let stmt: CompoundStatement = [
            .while(
                .identifier("predicate"),
                body: [
                    .while(.identifier("predicateInner"), body: [
                        .continue(targetLabel: "outer")
                    ]),
                ]
            ).labeled("outer"),
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{while}"]
                    n4 [label="predicate"]
                    n5 [label="{if predicate}"]
                    n6 [label="{compound}"]
                    n7 [label="{while}"]
                    n8 [label="predicateInner"]
                    n9 [label="{if predicateInner}"]
                    n10 [label="{compound}"]
                    n11 [label="{continue outer}"]
                    n12 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n9 -> n3 [color="#aa3333", label="false", penwidth=0.5]
                    n11 -> n3 [color="#aa3333", penwidth=0.5]
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6 [label="true"]
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9
                    n9 -> n10 [label="true"]
                    n10 -> n11
                    n5 -> n12 [label="false"]
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testWhileLoop_labeledBreak() {
        let stmt: CompoundStatement = [
            .while(
                .identifier("predicate"),
                body: [
                    .while(.identifier("predicateInner"), body: [
                        .break(targetLabel: "outer")
                    ]),
                ]
            ).labeled("outer"),
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{while}"]
                    n4 [label="predicate"]
                    n5 [label="{if predicate}"]
                    n6 [label="{compound}"]
                    n7 [label="{while}"]
                    n8 [label="predicateInner"]
                    n9 [label="{if predicateInner}"]
                    n10 [label="{compound}"]
                    n11 [label="{break outer}"]
                    n12 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n9 -> n3 [color="#aa3333", label="false", penwidth=0.5]
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6 [label="true"]
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9
                    n9 -> n10 [label="true"]
                    n10 -> n11
                    n5 -> n12 [label="false"]
                    n11 -> n12
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testWhileLoop_withBreakAndContinuePaths() {
        let stmt: CompoundStatement = [
            Statement.while(
                .identifier("whilePredicate"),
                body: [
                    .if(
                        .identifier("ifPredicate"),
                        body: [.break()],
                        else: [
                            .expression(.identifier("preContinue")),
                            .continue(),
                        ]
                    ),
                    .expression(.identifier("postIf"))
                ]
            ),
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
                    n9 [label="ifPredicate"]
                    n10 [label="{if ifPredicate}"]
                    n11 [label="{compound}"]
                    n12 [label="{compound}"]
                    n13 [label="{exp}"]
                    n14 [label="{break}"]
                    n15 [label="preContinue"]
                    n16 [label="{continue}"]
                    n17 [label="{exp}"]
                    n18 [label="postIf"]
                    n19 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n16 -> n3 [color="#aa3333", penwidth=0.5]
                    n18 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6 [label="true"]
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9
                    n9 -> n10
                    n10 -> n11 [label="false"]
                    n10 -> n12 [label="true"]
                    n11 -> n13
                    n12 -> n14
                    n13 -> n15
                    n15 -> n16
                    n17 -> n18
                    n5 -> n19 [label="false"]
                    n14 -> n19
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testWhileLoop_multiClause() {
        let stmt: CompoundStatement = [
            Statement.while(
                clauses: [
                    .init(expression: .identifier("predicate1")),
                    .init(pattern: .expression(.identifier("pattern2")), expression: .identifier("predicate2")),
                ],
                body: [
                    .expression(.identifier("loopBody"))
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
                    n3 [label="{while}"]
                    n4 [label="predicate1"]
                    n5 [label="{if predicate1}"]
                    n6 [label="pattern2"]
                    n7 [label="predicate2"]
                    n8 [label="{if pattern2 = predicate2}"]
                    n9 [label="{compound}"]
                    n10 [label="{exp}"]
                    n11 [label="loopBody"]
                    n12 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n11 -> n3 [color="#aa3333", penwidth=0.5]
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6 [label="true"]
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9 [label="true"]
                    n9 -> n10
                    n10 -> n11
                    n5 -> n12 [label="false"]
                    n8 -> n12 [label="false"]
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testRepeatWhileLoop() {
        let stmt: CompoundStatement = [
            Statement.repeatWhile(
                .identifier("predicate"),
                body: [
                    .expression(.identifier("loopBody"))
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
                    n3 [label="{compound}"]
                    n4 [label="{exp}"]
                    n5 [label="loopBody"]
                    n6 [label="predicate"]
                    n7 [label="{repeat-while}"]
                    n8 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n7 -> n3 [color="#aa3333", penwidth=0.5]
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testRepeatWhileLoop_empty() {
        let stmt: CompoundStatement = [
            Statement.repeatWhile(
                .identifier("predicate"),
                body: []
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
                    n3 [label="{compound}"]
                    n4 [label="predicate"]
                    n5 [label="{repeat-while}"]
                    n6 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n5 -> n3 [color="#aa3333", penwidth=0.5]
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testRepeatWhileLoop_labeledContinue() {
        let stmt: CompoundStatement = [
            .repeatWhile(
                .identifier("predicate"),
                body: [
                    .while(.identifier("predicateInner"), body: [
                        .continue(targetLabel: "outer"),
                    ]),
                ]
            ).labeled("outer"),
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{compound}"]
                    n4 [label="{while}"]
                    n5 [label="predicateInner"]
                    n6 [label="{if predicateInner}"]
                    n7 [label="{compound}"]
                    n8 [label="predicate"]
                    n9 [label="{continue outer}"]
                    n10 [label="{repeat-while}"]
                    n11 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n10 -> n3 [color="#aa3333", penwidth=0.5]
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7 [label="true"]
                    n6 -> n8 [label="false"]
                    n9 -> n8
                    n7 -> n9
                    n8 -> n10
                    n10 -> n11
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testRepeatWhileLoop_labeledBreak() {
        let stmt: CompoundStatement = [
            .repeatWhile(
                .identifier("predicate"),
                body: [
                    .while(.identifier("predicateInner"), body: [
                        .break(targetLabel: "outer"),
                    ]),
                ]
            ).labeled("outer"),
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{compound}"]
                    n4 [label="{while}"]
                    n5 [label="predicateInner"]
                    n6 [label="{if predicateInner}"]
                    n7 [label="predicate"]
                    n8 [label="{compound}"]
                    n9 [label="{break outer}"]
                    n10 [label="{repeat-while}"]
                    n11 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n10 -> n3 [color="#aa3333", penwidth=0.5]
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7 [label="false"]
                    n6 -> n8 [label="true"]
                    n8 -> n9
                    n7 -> n10
                    n9 -> n11
                    n10 -> n11
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testRepeatWhileLoop_break() {
        let stmt: CompoundStatement = [
            Statement.repeatWhile(
                .identifier("predicate"),
                body: [
                    .break()
                ]
            ),
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph, expectsUnreachable: true)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{compound}"]
                    n4 [label="{break}"]
                    n5 [label="predicate"]
                    n6 [label="{repeat-while}"]
                    n7 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n6 -> n3
                    n3 -> n4
                    n5 -> n6
                    n4 -> n7
                    n6 -> n7
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testForLoop() {
        let stmt: CompoundStatement = [
            Statement.for(
                .identifier("i"),
                .identifier("i"),
                body: [
                    .expression(.identifier("b"))
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
                    n3 [label="i"]
                    n4 [label="{for}"]
                    n5 [label="{compound}"]
                    n6 [label="{exp}"]
                    n7 [label="b"]
                    n8 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n7 -> n4 [color="#aa3333", penwidth=0.5]
                    n4 -> n5 [label="next"]
                    n5 -> n6
                    n6 -> n7
                    n4 -> n8 [label="end"]
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testForLoop_empty() {
        let stmt: CompoundStatement = [
            Statement.for(
                .identifier("i"),
                .identifier("i"),
                body: []
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
                    n3 [label="i"]
                    n4 [label="{for}"]
                    n5 [label="{compound}"]
                    n6 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n5 -> n4 [color="#aa3333", penwidth=0.5]
                    n4 -> n5 [label="next"]
                    n4 -> n6 [label="end"]
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testForLoop_labeledContinue() {
        let stmt: CompoundStatement = [
            Statement.for(
                .identifier("i"),
                .identifier("i"),
                body: [
                    .while(.identifier("predicateInner"), body: [
                        .continue(targetLabel: "outer")
                    ]),
                ]
            ).labeled("outer"),
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="i"]
                    n4 [label="{for}"]
                    n5 [label="{compound}"]
                    n6 [label="{while}"]
                    n7 [label="predicateInner"]
                    n8 [label="{if predicateInner}"]
                    n9 [label="{compound}"]
                    n10 [label="{continue outer}"]
                    n11 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n8 -> n4 [color="#aa3333", label="false", penwidth=0.5]
                    n10 -> n4 [color="#aa3333", penwidth=0.5]
                    n4 -> n5 [label="next"]
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9 [label="true"]
                    n9 -> n10
                    n4 -> n11 [label="end"]
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testForLoop_labeledBreak() {
        let stmt: CompoundStatement = [
            Statement.for(
                .identifier("i"),
                .identifier("i"),
                body: [
                    .while(.identifier("predicateInner"), body: [
                        .break(targetLabel: "outer")
                    ]),
                ]
            ).labeled("outer"),
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="i"]
                    n4 [label="{for}"]
                    n5 [label="{compound}"]
                    n6 [label="{while}"]
                    n7 [label="predicateInner"]
                    n8 [label="{if predicateInner}"]
                    n9 [label="{compound}"]
                    n10 [label="{break outer}"]
                    n11 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n8 -> n4 [color="#aa3333", label="false", penwidth=0.5]
                    n4 -> n5 [label="next"]
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9 [label="true"]
                    n9 -> n10
                    n4 -> n11 [label="end"]
                    n10 -> n11
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testForLoop_whereClause() {
        let stmt: CompoundStatement = [
            Statement.for(
                .identifier("i"),
                .identifier("a"),
                whereClause: .identifier("b"),
                body: [
                    .expression(.identifier("c"))
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
                    n3 [label="a"]
                    n4 [label="{for}"]
                    n5 [label="b"]
                    n6 [label="{compound}"]
                    n7 [label="{exp}"]
                    n8 [label="c"]
                    n9 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n8 -> n4 [color="#aa3333", penwidth=0.5]
                    n4 -> n5 [label="next"]
                    n5 -> n6 [label="true"]
                    n6 -> n7
                    n7 -> n8
                    n4 -> n9 [label="end"]
                    n5 -> n9 [label="false"]
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testReturnStatement() {
        let stmt: CompoundStatement = [
            .return(nil),
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{return}"]
                    n4 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testReturnStatement_withExpression() {
        let stmt: CompoundStatement = [
            .return(.identifier("exp")),
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="exp"]
                    n4 [label="{return exp}"]
                    n5 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testReturnStatement_inLoop() {
        let stmt: CompoundStatement = [
            Statement.while(
                .identifier("predicate"),
                body: [
                    .return(nil),
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
                    n3 [label="{while}"]
                    n4 [label="predicate"]
                    n5 [label="{if predicate}"]
                    n6 [label="{compound}"]
                    n7 [label="{return}"]
                    n8 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6 [label="true"]
                    n6 -> n7
                    n5 -> n8 [label="false"]
                    n7 -> n8
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testReturnStatement_skipRemaining() {
        let stmt: CompoundStatement = [
            .expression(.identifier("preReturn")),
            .return(nil),
            .expression(.identifier("postReturn")),
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
                    n4 [label="preReturn"]
                    n5 [label="{return}"]
                    n6 [label="{exp}"]
                    n7 [label="postReturn"]
                    n8 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n6 -> n7
                    n5 -> n8
                    n7 -> n8
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testThrowStatement() {
        let stmt: CompoundStatement = [
            Statement.while(
                .identifier("predicate"),
                body: [
                    .throw(.identifier("Error"))
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
                    n3 [label="{while}"]
                    n4 [label="predicate"]
                    n5 [label="{if predicate}"]
                    n6 [label="{compound}"]
                    n7 [label="Error"]
                    n8 [label="{throw Error}"]
                    n9 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6 [label="true"]
                    n6 -> n7
                    n7 -> n8
                    n5 -> n9 [label="false"]
                    n8 -> n9
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testThrowStatement_errorFlow() {
        let stmt: CompoundStatement = [
            .expression(.identifier("preError")),
            .throw(.identifier("Error")),
            .expression(.identifier("postError")),
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
                    n4 [label="preError"]
                    n5 [label="Error"]
                    n6 [label="{throw Error}"]
                    n7 [label="{exp}"]
                    n8 [label="postError"]
                    n9 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n7 -> n8
                    n6 -> n9
                    n8 -> n9
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testThrowStatement_conditionalErrorFlow() {
        let stmt: CompoundStatement = [
            .expression(.identifier("preError")),
            .if(.identifier("a"), body: [
                .throw(.identifier("Error")),
            ]),
            .expression(.identifier("postError")),
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
                    n4 [label="preError"]
                    n5 [label="{exp}"]
                    n6 [label="{if}"]
                    n7 [label="a"]
                    n8 [label="{if a}"]
                    n9 [label="{compound}"]
                    n10 [label="{exp}"]
                    n11 [label="Error"]
                    n12 [label="postError"]
                    n13 [label="{throw Error}"]
                    n14 [label="exit"]
                
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
                    n13 -> n14
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testBreakStatement() {
        let stmt: CompoundStatement = [
            Statement.while(
                .identifier("v"),
                body: [
                    .break()
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
                    n3 [label="{while}"]
                    n4 [label="v"]
                    n5 [label="{if v}"]
                    n6 [label="{compound}"]
                    n7 [label="{break}"]
                    n8 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6 [label="true"]
                    n6 -> n7
                    n5 -> n8 [label="false"]
                    n7 -> n8
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testBreak_labeled_loopDefer() {
        let stmt: CompoundStatement = [
            Statement.for(
                .identifier("a"),
                .identifier("a"),
                body: [
                    Statement.while(
                        .identifier("b"),
                        body: [
                            .defer([
                                .expression(.identifier("deferred"))
                            ]),
                            .if(
                                .identifier("predicate"),
                                body: [
                                    .break(targetLabel: "outer")
                                ]
                            ),
                        ]
                    )
                ]
            ).labeled("outer"),
            .expression(.identifier("b")),
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="a"]
                    n4 [label="{for}"]
                    n5 [label="{compound}"]
                    n6 [label="{exp}"]
                    n7 [label="{while}"]
                    n8 [label="b"]
                    n9 [label="b"]
                    n10 [label="{if b}"]
                    n11 [label="{compound}"]
                    n12 [label="{exp}"]
                    n13 [label="{if}"]
                    n14 [label="predicate"]
                    n15 [label="{if predicate}"]
                    n16 [label="{defer}"]
                    n17 [label="{compound}"]
                    n18 [label="{compound}"]
                    n19 [label="{break outer}"]
                    n20 [label="{exp}"]
                    n21 [label="{defer}"]
                    n22 [label="deferred"]
                    n23 [label="{compound}"]
                    n24 [label="{exp}"]
                    n25 [label="deferred"]
                    n26 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n10 -> n4 [color="#aa3333", label="false", penwidth=0.5]
                    n4 -> n5 [label="next"]
                    n4 -> n6 [label="end"]
                    n25 -> n6
                    n5 -> n7
                    n22 -> n7 [color="#aa3333", penwidth=0.5]
                    n6 -> n8
                    n7 -> n9
                    n9 -> n10
                    n10 -> n11 [label="true"]
                    n11 -> n12
                    n12 -> n13
                    n13 -> n14
                    n14 -> n15
                    n15 -> n16 [label="false"]
                    n15 -> n17 [label="true"]
                    n16 -> n18
                    n17 -> n19
                    n18 -> n20
                    n19 -> n21
                    n20 -> n22
                    n21 -> n23
                    n23 -> n24
                    n24 -> n25
                    n8 -> n26
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testContinueStatement() {
        let stmt: CompoundStatement = [
            Statement.while(
                .identifier("v"),
                body: [
                    .continue()
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
                    n3 [label="{while}"]
                    n4 [label="v"]
                    n5 [label="{if v}"]
                    n6 [label="{compound}"]
                    n7 [label="{continue}"]
                    n8 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n7 -> n3 [color="#aa3333", penwidth=0.5]
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6 [label="true"]
                    n6 -> n7
                    n5 -> n8 [label="false"]
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testContinueStatement_skippingOverRemainingOfMethod() {
        let stmt: CompoundStatement = [
            Statement.while(
                .identifier("v"),
                body: [
                    .continue(),
                    .expression(.identifier("v")),
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
                    n3 [label="{while}"]
                    n4 [label="v"]
                    n5 [label="{if v}"]
                    n6 [label="{compound}"]
                    n7 [label="{continue}"]
                    n8 [label="{exp}"]
                    n9 [label="v"]
                    n10 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n7 -> n3 [color="#aa3333", penwidth=0.5]
                    n9 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6 [label="true"]
                    n6 -> n7
                    n8 -> n9
                    n5 -> n10 [label="false"]
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testContinue_labeled_loopDefer() {
        let stmt: CompoundStatement = [
            Statement.for(
                .identifier("a"),
                .identifier("a"),
                body: [
                    Statement.while(
                        .identifier("b"),
                        body: [
                            .defer([
                                .expression(.identifier("deferred"))
                            ]),
                            .if(
                                .identifier("predicate"),
                                body: [
                                    .continue(targetLabel: "outer")
                                ]
                            ),
                        ]
                    )
                ]
            ).labeled("outer")
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="a"]
                    n4 [label="{for}"]
                    n5 [label="{compound}"]
                    n6 [label="{while}"]
                    n7 [label="b"]
                    n8 [label="{if b}"]
                    n9 [label="{compound}"]
                    n10 [label="{exp}"]
                    n11 [label="{if}"]
                    n12 [label="predicate"]
                    n13 [label="{if predicate}"]
                    n14 [label="{defer}"]
                    n15 [label="{compound}"]
                    n16 [label="{compound}"]
                    n17 [label="{continue outer}"]
                    n18 [label="{exp}"]
                    n19 [label="{defer}"]
                    n20 [label="deferred"]
                    n21 [label="{compound}"]
                    n22 [label="{exp}"]
                    n23 [label="deferred"]
                    n24 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n8 -> n4 [color="#aa3333", label="false", penwidth=0.5]
                    n23 -> n4 [color="#aa3333", penwidth=0.5]
                    n4 -> n5 [label="next"]
                    n5 -> n6
                    n20 -> n6 [color="#aa3333", penwidth=0.5]
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9 [label="true"]
                    n9 -> n10
                    n10 -> n11
                    n11 -> n12
                    n12 -> n13
                    n13 -> n14 [label="false"]
                    n13 -> n15 [label="true"]
                    n14 -> n16
                    n15 -> n17
                    n16 -> n18
                    n17 -> n19
                    n18 -> n20
                    n19 -> n21
                    n21 -> n22
                    n22 -> n23
                    n4 -> n24 [label="end"]
                }
                """
        )
        XCTAssert(graph.entry.node === stmt)
        XCTAssert(graph.exit.node === stmt)
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testDeferStatement() {
        let stmt: CompoundStatement = [
            Statement.defer([
                Statement.expression(.identifier("a")),
                Statement.expression(.identifier("b")),
            ]),
            Statement.expression(.identifier("c")),
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
                    n4 [label="c"]
                    n5 [label="{defer}"]
                    n6 [label="{compound}"]
                    n7 [label="{exp}"]
                    n8 [label="a"]
                    n9 [label="{exp}"]
                    n10 [label="b"]
                    n11 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9
                    n9 -> n10
                    n10 -> n11
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testDeferStatement_multiplePaths() {
        let stmt: CompoundStatement = [
            .expression(.identifier("a")),
            .do([
                .defer([
                    .expression(.identifier("b")),
                ]),
                .if(.identifier("predicate"), body: [
                    .throw(.identifier("error")),
                ]),
                .expression(.identifier("c")),
            ]).catch([
                .expression(.identifier("d")),
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
                    n3 [label="{exp}"]
                    n4 [label="a"]
                    n5 [label="{do}"]
                    n6 [label="{compound}"]
                    n7 [label="{exp}"]
                    n8 [label="{if}"]
                    n9 [label="predicate"]
                    n10 [label="{if predicate}"]
                    n11 [label="{compound}"]
                    n12 [label="{exp}"]
                    n13 [label="error"]
                    n14 [label="c"]
                    n15 [label="{throw error}"]
                    n16 [label="{defer}"]
                    n17 [label="{defer}"]
                    n18 [label="{compound}"]
                    n19 [label="{compound}"]
                    n20 [label="{exp}"]
                    n21 [label="{exp}"]
                    n22 [label="b"]
                    n23 [label="b"]
                    n24 [label="{catch}"]
                    n25 [label="{compound}"]
                    n26 [label="{exp}"]
                    n27 [label="d"]
                    n28 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9
                    n9 -> n10
                    n10 -> n11 [label="true"]
                    n10 -> n12 [label="false"]
                    n11 -> n13
                    n12 -> n14
                    n13 -> n15
                    n14 -> n16
                    n15 -> n17
                    n16 -> n18
                    n17 -> n19
                    n18 -> n20
                    n19 -> n21
                    n20 -> n22
                    n21 -> n23
                    n23 -> n24
                    n24 -> n25
                    n25 -> n26
                    n26 -> n27
                    n22 -> n28
                    n27 -> n28
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testDeferStatement_inIf() {
        let stmt: CompoundStatement = [
            Statement.if(
                .identifier("a"),
                body: [
                    Statement.defer([
                        Statement.expression(.identifier("b")),
                        Statement.expression(.identifier("c")),
                    ]),
                    Statement.expression(.identifier("d")),
                ]
            ),
            Statement.expression(.identifier("e")),
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
                    n5 [label="a"]
                    n6 [label="{if a}"]
                    n7 [label="{compound}"]
                    n8 [label="{exp}"]
                    n9 [label="{exp}"]
                    n10 [label="e"]
                    n11 [label="d"]
                    n12 [label="{defer}"]
                    n13 [label="{compound}"]
                    n14 [label="{exp}"]
                    n15 [label="b"]
                    n16 [label="{exp}"]
                    n17 [label="c"]
                    n18 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7 [label="true"]
                    n6 -> n8 [label="false"]
                    n17 -> n8
                    n7 -> n9
                    n8 -> n10
                    n9 -> n11
                    n11 -> n12
                    n12 -> n13
                    n13 -> n14
                    n14 -> n15
                    n15 -> n16
                    n16 -> n17
                    n10 -> n18
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testDeferStatement_inIfElse() {
        let stmt: CompoundStatement = [
            Statement.if(
                .identifier("a"),
                body: [
                    Statement.defer([
                        Statement.expression(.identifier("b"))
                    ]),
                    Statement.expression(.identifier("c")),
                ],
                else: [
                    Statement.defer([
                        Statement.expression(.identifier("d"))
                    ]),
                    Statement.expression(.identifier("e")),
                ]
            ),
            Statement.expression(.identifier("f")),
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
                    n5 [label="a"]
                    n6 [label="{if a}"]
                    n7 [label="{compound}"]
                    n8 [label="{compound}"]
                    n9 [label="{exp}"]
                    n10 [label="{exp}"]
                    n11 [label="c"]
                    n12 [label="e"]
                    n13 [label="{defer}"]
                    n14 [label="{defer}"]
                    n15 [label="{compound}"]
                    n16 [label="{compound}"]
                    n17 [label="{exp}"]
                    n18 [label="{exp}"]
                    n19 [label="b"]
                    n20 [label="d"]
                    n21 [label="{exp}"]
                    n22 [label="f"]
                    n23 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7 [label="true"]
                    n6 -> n8 [label="false"]
                    n7 -> n9
                    n8 -> n10
                    n9 -> n11
                    n10 -> n12
                    n11 -> n13
                    n12 -> n14
                    n13 -> n15
                    n14 -> n16
                    n15 -> n17
                    n16 -> n18
                    n17 -> n19
                    n18 -> n20
                    n19 -> n21
                    n20 -> n21
                    n21 -> n22
                    n22 -> n23
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testDeferStatement_inLoop() {
        let stmt: CompoundStatement = [
            Statement.while(
                .identifier("a"),
                body: [
                    Statement.defer([
                        Statement.expression(.identifier("b"))
                    ]),
                    Statement.expression(.identifier("c")),
                ]
            ),
            Statement.expression(.identifier("d")),
        ]

        let graph = ControlFlowGraph.forCompoundStatement(stmt)

        sanitize(graph)
        assertGraphviz(
            graph: graph,
            matches: """
                digraph flow {
                    n1 [label="entry"]
                    n2 [label="{compound}"]
                    n3 [label="{while}"]
                    n4 [label="a"]
                    n5 [label="{if a}"]
                    n6 [label="{compound}"]
                    n7 [label="{exp}"]
                    n8 [label="{exp}"]
                    n9 [label="d"]
                    n10 [label="c"]
                    n11 [label="{defer}"]
                    n12 [label="{compound}"]
                    n13 [label="{exp}"]
                    n14 [label="b"]
                    n15 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n14 -> n3 [color="#aa3333", penwidth=0.5]
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6 [label="true"]
                    n5 -> n7 [label="false"]
                    n6 -> n8
                    n7 -> n9
                    n8 -> n10
                    n10 -> n11
                    n11 -> n12
                    n12 -> n13
                    n13 -> n14
                    n9 -> n15
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testDeferStatement_inLoopWithBreak() {
        let stmt: CompoundStatement = [
            Statement.while(
                .identifier("a"),
                body: [
                    Statement.defer([
                        Statement.expression(.identifier("b"))
                    ]),
                    Statement.expression(.identifier("c")),
                    Statement.break(),
                ]
            ),
            Statement.expression(.identifier("d")),
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
                    n4 [label="a"]
                    n5 [label="{if a}"]
                    n6 [label="{compound}"]
                    n7 [label="{exp}"]
                    n8 [label="{exp}"]
                    n9 [label="d"]
                    n10 [label="c"]
                    n11 [label="{break}"]
                    n12 [label="{defer}"]
                    n13 [label="{compound}"]
                    n14 [label="{exp}"]
                    n15 [label="b"]
                    n16 [label="{defer}"]
                    n17 [label="{compound}"]
                    n18 [label="{exp}"]
                    n19 [label="b"]
                    n20 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n19 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6 [label="true"]
                    n5 -> n7 [label="false"]
                    n15 -> n7
                    n6 -> n8
                    n7 -> n9
                    n8 -> n10
                    n10 -> n11
                    n11 -> n12
                    n12 -> n13
                    n13 -> n14
                    n14 -> n15
                    n16 -> n17
                    n17 -> n18
                    n18 -> n19
                    n9 -> n20
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testDeferStatement_inRepeatWhileLoop() {
        let stmt: CompoundStatement = [
            Statement.repeatWhile(
                .identifier("predicate"),
                body: [
                    .defer([
                        .expression(.identifier("defer"))
                    ]),
                    .expression(.identifier("loopBody")),
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
                    n3 [label="{compound}"]
                    n4 [label="{exp}"]
                    n5 [label="loopBody"]
                    n6 [label="{defer}"]
                    n7 [label="{compound}"]
                    n8 [label="{exp}"]
                    n9 [label="defer"]
                    n10 [label="predicate"]
                    n11 [label="{repeat-while}"]
                    n12 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n11 -> n3 [color="#aa3333", penwidth=0.5]
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9
                    n9 -> n10
                    n10 -> n11
                    n11 -> n12
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }

    func testDeferStatement_interwoven() {
        let stmt: CompoundStatement = [
            Statement.defer([
                Statement.expression(.identifier("a")),
            ]),
            Statement.expression(.identifier("b")),
            Statement.if(
                .identifier("predicate"),
                body: [
                    .return(.constant(0)),
                ]
            ),
            Statement.defer([
                Statement.expression(.identifier("c")),
            ]),
            Statement.expression(.identifier("d")),
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
                    n4 [label="b"]
                    n5 [label="{exp}"]
                    n6 [label="{if}"]
                    n7 [label="predicate"]
                    n8 [label="{if predicate}"]
                    n9 [label="{compound}"]
                    n10 [label="{exp}"]
                    n11 [label="0"]
                    n12 [label="d"]
                    n13 [label="{return 0}"]
                    n14 [label="{defer}"]
                    n15 [label="{defer}"]
                    n16 [label="{compound}"]
                    n17 [label="{compound}"]
                    n18 [label="{exp}"]
                    n19 [label="{exp}"]
                    n20 [label="c"]
                    n21 [label="c"]
                    n22 [label="{defer}"]
                    n23 [label="{defer}"]
                    n24 [label="{compound}"]
                    n25 [label="{compound}"]
                    n26 [label="{exp}"]
                    n27 [label="{exp}"]
                    n28 [label="a"]
                    n29 [label="a"]
                    n30 [label="exit"]
                
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
                    n14 -> n16
                    n15 -> n17
                    n16 -> n18
                    n17 -> n19
                    n18 -> n20
                    n19 -> n21
                    n20 -> n22
                    n21 -> n23
                    n22 -> n24
                    n23 -> n25
                    n24 -> n26
                    n25 -> n27
                    n26 -> n28
                    n27 -> n29
                    n28 -> n30
                    n29 -> n30
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 2)
    }

    func testDeferStatement_orderingOnJumps() {
        let stmt: CompoundStatement = [
            .do([
                .defer([
                    .expression(.identifier("defer_a")),
                ]),
                .defer([
                    .expression(.identifier("defer_b")),
                ]),
                .throw(.identifier("Error")),
            ]).catch([
                .expression(.identifier("errorHandler")),
            ]),
            .expression(.identifier("postDo")),
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
                    n5 [label="Error"]
                    n6 [label="{throw Error}"]
                    n7 [label="{defer}"]
                    n8 [label="{compound}"]
                    n9 [label="{exp}"]
                    n10 [label="defer_b"]
                    n11 [label="{defer}"]
                    n12 [label="{compound}"]
                    n13 [label="{exp}"]
                    n14 [label="defer_a"]
                    n15 [label="{catch}"]
                    n16 [label="{compound}"]
                    n17 [label="{exp}"]
                    n18 [label="errorHandler"]
                    n19 [label="{exp}"]
                    n20 [label="postDo"]
                    n21 [label="{defer}"]
                    n22 [label="{compound}"]
                    n23 [label="{exp}"]
                    n24 [label="defer_b"]
                    n25 [label="{defer}"]
                    n26 [label="{compound}"]
                    n27 [label="{exp}"]
                    n28 [label="defer_a"]
                    n29 [label="exit"]
                
                    n1 -> n2
                    n2 -> n3
                    n3 -> n4
                    n4 -> n5
                    n5 -> n6
                    n6 -> n7
                    n7 -> n8
                    n8 -> n9
                    n9 -> n10
                    n10 -> n11
                    n11 -> n12
                    n12 -> n13
                    n13 -> n14
                    n14 -> n15
                    n15 -> n16
                    n16 -> n17
                    n17 -> n18
                    n18 -> n19
                    n28 -> n19
                    n19 -> n20
                    n21 -> n22
                    n22 -> n23
                    n23 -> n24
                    n24 -> n25
                    n25 -> n26
                    n26 -> n27
                    n27 -> n28
                    n20 -> n29
                }
                """
        )
        XCTAssertEqual(graph.nodesConnected(from: graph.entry).count, 1)
        XCTAssertEqual(graph.nodesConnected(towards: graph.exit).count, 1)
    }
}
