import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport

@testable import SwiftASTMacros

class SwiftASTStatementsMacroTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "ast_expandStatements": SwiftASTStatementsMacro.self,
    ]

    func testMacro_compoundStatement() {
        assertMacroExpansion("""
            #ast_expandStatements({
                let a: Int = 0
                print(a.description)
            })
            """,
            expandedSource: #"""
            CompoundStatement(statements: [VariableDeclarationsStatement(
                decl: [StatementVariableDeclaration(
                identifier: "a",
                storage: ValueStorage(
                type: SwiftType.nominal(NominalSwiftType.typeName("Int")),
                ownership: Ownership.strong,
                isConstant: true
                                ),
                initialization: ConstantExpression.constant(
                Constant.int(0, .decimal)
                                )
                            )]
                    ), ExpressionsStatement(
                expressions: [PostfixExpression(
                exp: IdentifierExpression(identifier: "print"),
                op: FunctionCallPostfix(
                    arguments: [FunctionArgument(
                label: nil,
                expression: PostfixExpression(
                exp: IdentifierExpression(identifier: "a"),
                op: MemberPostfix(name: "description").withOptionalAccess(kind: Postfix.OptionalAccessKind.none)
                                            )
                                        )]
                ).withOptionalAccess(kind: Postfix.OptionalAccessKind.none)
                            )]
                    )])
            """#,
            macros: testMacros)
    }

    func testMacro_singleStatement_false() {
        assertMacroExpansion("""
            #ast_expandStatements(singleStatement: false, {
                if a {
                    b
                }
            })
            """,
            expandedSource: #"""
            CompoundStatement(statements: [IfStatement(
                clauses: ConditionalClauses(
                clauses: [ConditionalClauseElement(
                expression: IdentifierExpression(identifier: "a")
                            )]
                        ),
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "b")]
                                )]),
                elseBody: nil
                    )])
            """#,
            macros: testMacros)
    }

    func testMacro_singleStatement_true() {
        assertMacroExpansion("""
            #ast_expandStatements(singleStatement: true, {
                if a {
                    b
                }
            })
            """,
            expandedSource: #"""
            IfStatement(
                clauses: ConditionalClauses(
                clauses: [ConditionalClauseElement(
                expression: IdentifierExpression(identifier: "a")
                    )]
                ),
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "b")]
                        )]),
                elseBody: nil
            )
            """#,
            macros: testMacros)
    }

    // MARK: - Diagnostics tests

    func testMacro_diagnostics_expectedClosureArgument() {
        assertDiagnostics("""
            #ast_expandStatements()
            """,
            expandedSource: #"""
            #ast_expandStatements()
            """#, [
                DiagnosticSpec(
                    message: "Expected a closure expression",
                    line: 1,
                    column: 1
                )
            ])
    }

    func testMacro_diagnostics_singleStatement_notBoolean() {
        assertDiagnostics("""
            #ast_expandStatements(singleStatement: identifier, { })
            """,
            expandedSource: #"""
            #ast_expandStatements(singleStatement: identifier, { })
            """#, [
                DiagnosticSpec(
                    message: "Expected 'singleStatement' argument to be a boolean literal value.",
                    line: 1,
                    column: 1
                )
            ])
    }

    func testMacro_diagnostics_singleStatement_emptyClosure() {
        assertDiagnostics("""
            #ast_expandStatements(singleStatement: true, { })
            """,
            expandedSource: #"""
            #ast_expandStatements(singleStatement: true, { })
            """#, [
                DiagnosticSpec(
                    message: "Expected at least one statement within the closure with 'singleStatement'",
                    line: 1,
                    column: 1
                )
            ])
    }

    func testMacro_diagnostics_unknownLabel() {
        assertDiagnostics("""
            #ast_expandStatements(label: true, { })
            """,
            expandedSource: #"""
            #ast_expandStatements(label: true, { })
            """#, [
                DiagnosticSpec(
                    message: "Unrecognized argument label 'label'",
                    line: 1,
                    column: 1
                )
            ])
    }

    // MARK: - Test internals

    private func assertDiagnostics(
        _ macro: String,
        expandedSource: String,
        _ diagnostics: [DiagnosticSpec],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        assertMacroExpansion(
            macro,
            expandedSource: expandedSource,
            diagnostics: diagnostics,
            macros: testMacros,
            file: file,
            line: line
        )
    }
}
