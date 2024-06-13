import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport

@testable import SwiftASTMacros

class SwiftASTExpressionMacro_StatementTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "ast_expandExpression": SwiftASTExpressionMacro.self,
    ]

    func testMacro_break() {
        assertMacroExpansion("""
            #ast_expandExpression({
                break
                break abc
            })
            """,
            expandedSource: #"""
            BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [BreakStatement(targetLabel: nil), BreakStatement(targetLabel: "abc")])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_compound() {
        assertMacroExpansion("""
            #ast_expandExpression({ a; b; c })
            """,
            expandedSource: #"""
            BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "a")]
                        ), ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "b")]
                        ), ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "c")]
                        )])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_continue() {
        assertMacroExpansion("""
            #ast_expandExpression({
                continue
                continue abc
            })
            """,
            expandedSource: #"""
            BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [ContinueStatement(targetLabel: nil), ContinueStatement(targetLabel: "abc")])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_defer() {
        assertMacroExpansion("""
            #ast_expandExpression({
                defer { abc }
            })
            """,
            expandedSource: #"""
            BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [DeferStatement(
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "abc")]
                                    )])
                        )])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_do() {
        assertMacroExpansion("""
            #ast_expandExpression({
                do { abc }
                do { def } catch { ghi }
                do { jkl } catch errorName { mno }
            })
            """,
            expandedSource: #"""
            BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [DoStatement(
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "abc")]
                                    )]),
                catchBlocks: []
                        ), DoStatement(
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "def")]
                                    )]),
                catchBlocks: [CatchBlock(
                pattern: nil,
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "ghi")]
                                            )])
                                )]
                        ), DoStatement(
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "jkl")]
                                    )]),
                catchBlocks: [CatchBlock(
                pattern: Pattern.expression(IdentifierExpression(identifier: "errorName")),
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "mno")]
                                            )])
                                )]
                        )])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_repeatWhile() {
        assertMacroExpansion("""
            #ast_expandExpression({
                repeat {
                    abc
                } while def
            })
            """,
            expandedSource: #"""
            BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [RepeatWhileStatement(
                expression: IdentifierExpression(identifier: "def"),
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "abc")]
                                    )])
                        )])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_expressions() {
        assertMacroExpansion("""
            #ast_expandExpression({
                abc
                def = ghi
            })
            """,
            expandedSource: #"""
            BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "abc")]
                        ), ExpressionsStatement(
                expressions: [AssignmentExpression(
                lhs: IdentifierExpression(identifier: "def"),
                op: SwiftOperator.assign,
                rhs: IdentifierExpression(identifier: "ghi")
                                )]
                        )])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_fallthrough() {
        assertMacroExpansion("""
            #ast_expandExpression({ fallthrough })
            """,
            expandedSource: #"""
            BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [FallthroughStatement()])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_if() {
        assertMacroExpansion("""
            #ast_expandExpression({
                if a {
                    b
                }
            })
            """,
            expandedSource: #"""
            BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [IfStatement.if(
                clauses: ConditionalClauses(
                clauses: [ConditionalClauseElement(
                expression: IdentifierExpression(identifier: "a")
                                )]
                            ),
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "b")]
                                    )])
                        )])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_ifElse() {
        assertMacroExpansion("""
            #ast_expandExpression({
                if a {
                    b
                } else {
                    c
                }
            })
            """,
            expandedSource: #"""
            BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [IfStatement.if(
                clauses: ConditionalClauses(
                clauses: [ConditionalClauseElement(
                expression: IdentifierExpression(identifier: "a")
                                )]
                            ),
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "b")]
                                    )]),
                elseBody: .else(CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "c")]
                                        )]))
                        )])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_ifElseIf() {
        assertMacroExpansion("""
            #ast_expandExpression({
                if a {
                    b
                } else if c {
                    d
                }
            })
            """,
            expandedSource: #"""
            BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [IfStatement.if(
                clauses: ConditionalClauses(
                clauses: [ConditionalClauseElement(
                expression: IdentifierExpression(identifier: "a")
                                )]
                            ),
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "b")]
                                    )]),
                elseBody: .elseIf(IfStatement.if(
                clauses: ConditionalClauses(
                clauses: [ConditionalClauseElement(
                expression: IdentifierExpression(identifier: "c")
                                        )]
                                    ),
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "d")]
                                            )])
                                ))
                        )])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_guard() {
        assertMacroExpansion("""
            #ast_expandExpression({ guard abc, def else { } })
            """,
            expandedSource: #"""
            BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [GuardStatement(
                clauses: ConditionalClauses(
                clauses: [ConditionalClauseElement(
                expression: IdentifierExpression(identifier: "abc")
                                ), ConditionalClauseElement(
                expression: IdentifierExpression(identifier: "def")
                                )]
                            ),
                elseBody: CompoundStatement(statements: [])
                        )])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_for() {
        assertMacroExpansion("""
            #ast_expandExpression({ for a in b { } })
            """,
            expandedSource: #"""
            BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [ForStatement(
                pattern: Pattern.identifier("a"),
                exp: IdentifierExpression(identifier: "b"),
                body: CompoundStatement(statements: [])
                        )])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_localFunction() {
        assertMacroExpansion("""
            #ast_expandExpression({
                func abc(a: A, b: B, c: C?) -> D {
                    def
                }
            })
            """,
            expandedSource: #"""
            BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [LocalFunctionStatement(
                function: LocalFunction(
                signature: FunctionSignature(
                name: "abc",
                parameters: [ParameterSignature(
                label: "a",
                name: "a",
                type: SwiftType.nominal(NominalSwiftType.typeName("A")),
                isVariadic: false,
                hasDefaultValue: false
                                ), ParameterSignature(
                label: "b",
                name: "b",
                type: SwiftType.nominal(NominalSwiftType.typeName("B")),
                isVariadic: false,
                hasDefaultValue: false
                                ), ParameterSignature(
                label: "c",
                name: "c",
                type: SwiftType.optional(SwiftType.nominal(NominalSwiftType.typeName("C"))),
                isVariadic: false,
                hasDefaultValue: false
                                )],
                returnType: SwiftType.nominal(NominalSwiftType.typeName("D")),
                traits: FunctionSignature.Traits()
                            ),
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "def")]
                                    )])
                            )
                        )])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_return() {
        assertMacroExpansion("""
            #ast_expandExpression({
                return
                return a
            })
            """,
            expandedSource: #"""
            BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [ReturnStatement.return(), ReturnStatement.expression(IdentifierExpression(identifier: "a"))])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_switch() {
        assertMacroExpansion("""
            #ast_expandExpression({
                switch a {
                case b where c: break
                case d, e where f: break
                default: break
                }
            })
            """,
            expandedSource: #"""
            BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [SwitchStatement(
                exp: IdentifierExpression(identifier: "a"),
                cases: [SwitchCase(
                casePatterns: [SwitchCase.CasePattern(
                pattern: Pattern.expression(IdentifierExpression(identifier: "b")),
                whereClause: IdentifierExpression(identifier: "c")
                                        )],
                body: CompoundStatement(statements: [BreakStatement(targetLabel: nil)])
                                ), SwitchCase(
                casePatterns: [SwitchCase.CasePattern(
                pattern: Pattern.expression(IdentifierExpression(identifier: "d"))
                                        ), SwitchCase.CasePattern(
                pattern: Pattern.expression(IdentifierExpression(identifier: "e")),
                whereClause: IdentifierExpression(identifier: "f")
                                        )],
                body: CompoundStatement(statements: [BreakStatement(targetLabel: nil)])
                                )],
                defaultCase: SwitchDefaultCase(
                    statements: [BreakStatement(targetLabel: nil)]
                )
                        )])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_throw() {
        assertMacroExpansion("""
            #ast_expandExpression({
                throw abc
            })
            """,
            expandedSource: #"""
            BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [ThrowStatement.throw(IdentifierExpression(identifier: "abc"))])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_variableDeclarations() {
        assertMacroExpansion("""
            #ast_expandExpression({
                let a: Double = 0
                var b: Int = 1
            })
            """,
            expandedSource: #"""
            BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [VariableDeclarationsStatement(
                decl: [StatementVariableDeclaration(
                identifier: "a",
                storage: ValueStorage(
                type: SwiftType.nominal(NominalSwiftType.typeName("Double")),
                ownership: Ownership.strong,
                isConstant: true
                                    ),
                initialization: ConstantExpression.constant(
                Constant.int(0, .decimal)
                                    )
                                )]
                        ), VariableDeclarationsStatement(
                decl: [StatementVariableDeclaration(
                identifier: "b",
                storage: ValueStorage(
                type: SwiftType.nominal(NominalSwiftType.typeName("Int")),
                ownership: Ownership.strong,
                isConstant: false
                                    ),
                initialization: ConstantExpression.constant(
                Constant.int(1, .decimal)
                                    )
                                )]
                        )])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_variableDeclarations_multipleBindings() {
        assertMacroExpansion("""
            #ast_expandExpression({
                let a: Int, b: Double = 0
            })
            """,
            expandedSource: #"""
            BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [VariableDeclarationsStatement(
                decl: [StatementVariableDeclaration(
                identifier: "a",
                storage: ValueStorage(
                type: SwiftType.nominal(NominalSwiftType.typeName("Int")),
                ownership: Ownership.strong,
                isConstant: true
                                    ),
                initialization: nil
                                ), StatementVariableDeclaration(
                identifier: "b",
                storage: ValueStorage(
                type: SwiftType.nominal(NominalSwiftType.typeName("Double")),
                ownership: Ownership.strong,
                isConstant: true
                                    ),
                initialization: ConstantExpression.constant(
                Constant.int(0, .decimal)
                                    )
                                )]
                        )])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_while() {
        assertMacroExpansion("""
            #ast_expandExpression({ while true { } })
            """,
            expandedSource: #"""
            BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [WhileStatement.while(
                clauses: ConditionalClauses(
                clauses: [ConditionalClauseElement(
                expression: ConstantExpression.constant(
                Constant.boolean(true )
                                    )
                                )]
                            ),
                body: CompoundStatement(statements: [])
                        )])
            )
            """#,
            macros: testMacros)
    }

    // MARK: Diagnostics tests

    func testMacro_diagnostic_unsupportedDecl() {
        assertDiagnostics("""
            #ast_expandExpression({
                class A { }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    class A { }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "Unsupported SwiftAST.Statement declaration kind as member of statements list.",
                    line: 2,
                    column: 5
                )
            ])
    }

    func testMacro_diagnostic_unsupportedConditional_availability() {
        assertDiagnostics("""
            #ast_expandExpression({
                if #available(*) {
                }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    if #available(*) {\n    }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "ConditionalClauseElement does not support #available conditionals.",
                    line: 2,
                    column: 8
                )
            ])
    }

    func testMacro_diagnostic_unsupportedConditional_implicitOptionalBindingName() {
        assertDiagnostics("""
            #ast_expandExpression({
                if let abc {
                }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    if let abc {\n    }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "ConditionalClauseElement does not support implicit optional unwraps.",
                    line: 2,
                    column: 8
                )
            ])
    }

    func testMacro_diagnostic_catchBlocksWithMultiplePatterns() {
        assertDiagnostics("""
            #ast_expandExpression({
                do {
                } catch a, b {
                }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    do {\n    } catch a, b {\n    }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "CatchBlock does not support catch blocks with more than one pattern.",
                    line: 3,
                    column: 13
                )
            ])
    }

    func testMacro_diagnostic_catchBlocksWithWhereClause() {
        assertDiagnostics("""
            #ast_expandExpression({
                do {
                } catch a where b {
                }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    do {\n    } catch a where b {\n    }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "CatchBlock does not support catch blocks with where clauses.",
                    line: 3,
                    column: 15
                )
            ])
    }

    func testMacro_diagnostic_switchStatement_interleavedIfConfig() {
        assertDiagnostics("""
            #ast_expandExpression({
                switch a {
                #if b
                case c: break
                #endif
                }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    switch a {\n    #if b\n    case c: break\n    #endif\n    }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "SwitchStatement does not support interleaved '#if' statements within cases.",
                    line: 3,
                    column: 5
                )
            ])
    }

    func testMacro_diagnostic_switchStatement_twoDefaultCases() {
        assertDiagnostics("""
            #ast_expandExpression({
                switch a {
                default: break
                default: break
                }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    switch a {\n    default: break\n    default: break\n    }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "Unexpected two default cases in switch statement",
                    line: 4,
                    column: 5
                )
            ])
    }

    func testMacro_diagnostic_forStatement_casePattern() {
        assertDiagnostics("""
            #ast_expandExpression({
                for case a in b {
                }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    for case a in b {\n    }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "ForStatement does not support 'case' iterator patterns.",
                    line: 2,
                    column: 9
                )
            ])
    }

    func testMacro_diagnostic_forStatement_try() {
        assertDiagnostics("""
            #ast_expandExpression({
                for try a in b {
                }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    for try a in b {\n    }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "ForStatement does not support 'try' iterator patterns.",
                    line: 2,
                    column: 9
                )
            ])
    }

    func testMacro_diagnostic_forStatement_await() {
        assertDiagnostics("""
            #ast_expandExpression({
                for await a in b {
                }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    for await a in b {\n    }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "ForStatement does not support 'await' iterator patterns.",
                    line: 2,
                    column: 9
                )
            ])
    }

    func testMacro_diagnostic_forStatementWhereClause() {
        assertDiagnostics("""
            #ast_expandExpression({
                for a in b where c {
                }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    for a in b where c {\n    }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "ForStatement does not support 'where' clauses.",
                    line: 2,
                    column: 16
                )
            ])
    }

    func testMacro_diagnostic_forStatement_typeAnnotation() {
        assertDiagnostics("""
            #ast_expandExpression({
                for a: A in b {
                }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    for a: A in b {\n    }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "ForStatement does not support type annotations.",
                    line: 2,
                    column: 10
                )
            ])
    }

    func testMacro_diagnostic_localFunctionStatement_attributes() {
        assertDiagnostics("""
            #ast_expandExpression({
                @attribute
                func a() {
                }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    @attribute\n    func a() {\n    }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "LocalFunctionStatement does not support attributes.",
                    line: 2,
                    column: 5
                )
            ])
    }

    func testMacro_diagnostic_localFunctionStatement_modifiers() {
        assertDiagnostics("""
            #ast_expandExpression({
                infix func a() {
                }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    infix func a() {\n    }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "LocalFunctionStatement does not support modifiers.",
                    line: 2,
                    column: 5
                )
            ])
    }

    func testMacro_diagnostic_localFunctionStatement_genericParameters() {
        assertDiagnostics("""
            #ast_expandExpression({
                func a<T>() {
                }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    func a<T>() {\n    }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "LocalFunctionStatement does not support generic parameters or generic where clauses.",
                    line: 2,
                    column: 11
                )
            ])
    }

    func testMacro_diagnostic_localFunctionStatement_genericWhereClause() {
        assertDiagnostics("""
            #ast_expandExpression({
                func a() where T: U {
                }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    func a() where T: U {\n    }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "LocalFunctionStatement does not support generic parameters or generic where clauses.",
                    line: 2,
                    column: 14
                )
            ])
    }

    func testMacro_diagnostic_localFunctionStatement_noBody() {
        assertDiagnostics("""
            #ast_expandExpression({
                func a()
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    func a()\n}"))
            """#, [
                DiagnosticSpec(
                    message: "LocalFunctionStatement requires a body.",
                    line: 2,
                    column: 5
                )
            ])
    }

    func testMacro_diagnostic_localFunctionStatement_functionSignature_parameterSignature_attributes() {
        assertDiagnostics("""
            #ast_expandExpression({
                func a(@B b: Int) {
                }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    func a(@B b: Int) {\n    }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "ParameterSignature does not support attributes.",
                    line: 2,
                    column: 12
                )
            ])
    }

    func testMacro_diagnostic_localFunctionStatement_functionSignature_parameterSignature_defaultValues() {
        assertDiagnostics("""
            #ast_expandExpression({
                func a(b: Int = 0) {
                }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    func a(b: Int = 0) {\n    }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "ParameterSignature does not support default values.",
                    line: 2,
                    column: 19
                )
            ])
    }

    func testMacro_diagnostic_localFunctionStatement_functionSignature_parameterSignature_asyncTrait() {
        assertDiagnostics("""
            #ast_expandExpression({
                func a() async {
                }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    func a() async {\n    }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "FunctionSignature does not support async trait.",
                    line: 2,
                    column: 14
                )
            ])
    }

    func testMacro_diagnostic_localFunctionStatement_functionSignature_parameterSignature_reasyncTrait() {
        assertDiagnostics("""
            #ast_expandExpression({
                func a() reasync {
                }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    func a() reasync {\n    }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "FunctionSignature does not support async trait.",
                    line: 2,
                    column: 14
                )
            ])
    }

    func testMacro_diagnostic_localFunctionStatement_functionSignature_parameterSignature_rethrowsTrait() {
        assertDiagnostics("""
            #ast_expandExpression({
                func a() rethrows {
                }
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    func a() rethrows {\n    }\n}"))
            """#, [
                DiagnosticSpec(
                    message: "FunctionSignature does not support rethrows trait.",
                    line: 2,
                    column: 14
                )
            ])
    }

    func testMacro_diagnostic_variableDeclarations_attributes() {
        assertDiagnostics("""
            #ast_expandExpression({
                @attr let a = 0
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    @attr let a = 0\n}"))
            """#, [
                DiagnosticSpec(
                    message: "VariableDeclarationsStatement does not support attributes.",
                    line: 2,
                    column: 5
                )
            ])
    }

    func testMacro_diagnostic_variableDeclarations_unsupportedModifier() {
        assertDiagnostics("""
            #ast_expandExpression({
                lazy let a: Int = 0
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    lazy let a: Int = 0\n}"))
            """#, [
                DiagnosticSpec(
                    message: "Unsupported declaration modifier.",
                    line: 2,
                    column: 5
                )
            ])
    }

    func testMacro_diagnostic_variableDeclarations_noTypeAnnotations() {
        assertDiagnostics("""
            #ast_expandExpression({
                let a = 0
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    let a = 0\n}"))
            """#, [
                DiagnosticSpec(
                    message: "StatementVariableDeclaration requires explicit type annotations.",
                    line: 2,
                    column: 9
                )
            ])
    }

    func testMacro_diagnostic_variableDeclarations_nonIdentifierPattern() {
        assertDiagnostics("""
            #ast_expandExpression({
                let (a, b): (Int, Double) = (0, 1)
            })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("{\n    let (a, b): (Int, Double) = (0, 1)\n}"))
            """#, [
                DiagnosticSpec(
                    message: "VariableDeclarationsStatement does not support non-identifier bindings.",
                    line: 2,
                    column: 9
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
