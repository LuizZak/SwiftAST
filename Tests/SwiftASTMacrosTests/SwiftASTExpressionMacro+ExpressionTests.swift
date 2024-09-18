import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport

@testable import SwiftASTMacros

class SwiftASTExpressionMacro_ExpressionTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "ast_expandExpression": SwiftASTExpressionMacro.self,
    ]

    func testMacro_binaryExpressionIntoAssignment() {
        assertMacroExpansion("""
            #ast_expandExpression(a = 1 + 1)
            """,
            expandedSource: #"""
            AssignmentExpression(
                lhs: IdentifierExpression(identifier: "a"),
                op: SwiftOperator.assign,
                rhs: BinaryExpression(
                lhs: ConstantExpression.constant(
                Constant.int(1 , .decimal)
                ),
                op: SwiftOperator.add,
                rhs: ConstantExpression.constant(
                Constant.int(1, .decimal)
                )
                )
            )
            """#,
            macros: testMacros)
    }

    func testMacro_expression_arrayLiteral() {
        assertMacroExpansion("""
            #ast_expandExpression([0, 1, 2])
            """,
            expandedSource: #"""
            ArrayLiteralExpression(items: [ConstantExpression.constant(
                Constant.int(0, .decimal)
                    ), ConstantExpression.constant(
                Constant.int(1, .decimal)
                    ), ConstantExpression.constant(
                Constant.int(2, .decimal)
                    )])
            """#,
            macros: testMacros)
    }

    func testMacro_expression_assignment() {
        assertMacroExpansion("""
            #ast_expandExpression(a = b)
            """,
            expandedSource: #"""
            AssignmentExpression(
                lhs: IdentifierExpression(identifier: "a"),
                op: SwiftOperator.assign,
                rhs: IdentifierExpression(identifier: "b")
            )
            """#,
            macros: testMacros)
    }

    func testMacro_expression_binary() {
        assertMacroExpansion("""
            #ast_expandExpression(a + b)
            """,
            expandedSource: #"""
            BinaryExpression(
                lhs: IdentifierExpression(identifier: "a"),
                op: SwiftOperator.add,
                rhs: IdentifierExpression(identifier: "b")
            )
            """#,
            macros: testMacros)
    }

    func testMacro_expression_blockLiteral() {
        assertMacroExpansion("""
            #ast_expandExpression(a = { b })
            """,
            expandedSource: #"""
            AssignmentExpression(
                lhs: IdentifierExpression(identifier: "a"),
                op: SwiftOperator.assign,
                rhs: BlockLiteralExpression(
                parameters: [],
                returnType: SwiftType.void,
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "b")]
                        )])
                )
            )
            """#,
            macros: testMacros)
    }

    func testMacro_expression_cast() {
        assertMacroExpansion("""
            #ast_expandExpression(a as? B)
            #ast_expandExpression(a as B)
            """,
            expandedSource: #"""
            CastExpression(
                exp: IdentifierExpression(identifier: "a"),
                type: SwiftType.nominal(NominalSwiftType.typeName("B")),
                isOptionalCast: true
            )
            CastExpression(
                exp: IdentifierExpression(identifier: "a"),
                type: SwiftType.nominal(NominalSwiftType.typeName("B")),
                isOptionalCast: false
            )
            """#,
            macros: testMacros)
    }

    func testMacro_expression_constant() {
        assertMacroExpansion(#"""
            #ast_expandExpression(123.456)
            #ast_expandExpression(true)
            #ast_expandExpression(false)
            #ast_expandExpression(123456)
            #ast_expandExpression("aStr \n ing")
            #ast_expandExpression(nil)
            """#,
            expandedSource: #"""
            ConstantExpression(
                constant: Constant.double(123.456)
            )
            ConstantExpression(
                constant: Constant.boolean(true)
            )
            ConstantExpression(
                constant: Constant.boolean(false)
            )
            ConstantExpression.constant(
                Constant.int(123456, .decimal)
            )
            ConstantExpression(
                constant: Constant.string("aStr \n ing")
            )
            ConstantExpression(constant: Constant.nil)
            """#,
            macros: testMacros)
    }

    func testMacro_expression_dictionaryLiteral() {
        assertMacroExpansion(#"""
            #ast_expandExpression([:])
            #ast_expandExpression(["a": b])
            """#,
            expandedSource: #"""
            DictionaryLiteralExpression(pairs: [])
            DictionaryLiteralExpression(pairs: [ExpressionDictionaryPair(key: ConstantExpression(
                constant: Constant.string("a")
                        ), value: IdentifierExpression(identifier: "b"))])
            """#,
            macros: testMacros)
    }

    func testMacro_expression_identifier() {
        assertMacroExpansion(#"""
            #ast_expandExpression(a)
            """#,
            expandedSource: #"""
            IdentifierExpression(identifier: "a")
            """#,
            macros: testMacros)
    }

    func testMacro_expression_parens() {
        assertMacroExpansion(#"""
            #ast_expandExpression((a))
            """#,
            expandedSource: #"""
            ParensExpression(
                exp: IdentifierExpression(identifier: "a")
            )
            """#,
            macros: testMacros)
    }

    func testMacro_expression_postfix() {
        assertMacroExpansion(#"""
            #ast_expandExpression(a.b()?[c: c]?.d)
            """#,
            expandedSource: #"""
            PostfixExpression(
                exp: PostfixExpression(
                exp: PostfixExpression(
                exp: PostfixExpression(
                exp: IdentifierExpression(identifier: "a"),
                op: MemberPostfix(
                    name: "b",
                    argumentNames: nil
                ).withOptionalAccess(kind: Postfix.OptionalAccessKind.none)
                ),
                op: FunctionCallPostfix(
                    arguments: []
                ).withOptionalAccess(kind: Postfix.OptionalAccessKind.none)
                ),
                op: SubscriptPostfix(
                    arguments: [FunctionArgument(
                label: "c",
                expression: IdentifierExpression(identifier: "c")
                        )]
                ).withOptionalAccess(kind: Postfix.OptionalAccessKind.safeUnwrap)
                ),
                op: MemberPostfix(
                    name: "d",
                    argumentNames: nil
                ).withOptionalAccess(kind: Postfix.OptionalAccessKind.safeUnwrap)
            )
            """#,
            macros: testMacros)
    }

    func testMacro_expression_postfix_member_argumentNames() {
        assertMacroExpansion("""
            #ast_expandExpression(a.b(c:_:))
            """,
            expandedSource: #"""
            PostfixExpression(
                exp: IdentifierExpression(identifier: "a"),
                op: MemberPostfix(
                    name: "b",
                    argumentNames: [MemberPostfix.ArgumentName(identifier: "c"), MemberPostfix.ArgumentName(identifier: "_")]
                ).withOptionalAccess(kind: Postfix.OptionalAccessKind.none)
            )
            """#,
            macros: testMacros)
    }

    func testMacro_expression_prefix() {
        assertMacroExpansion(#"""
            #ast_expandExpression(-a)
            """#,
            expandedSource: #"""
            UnaryExpression(
                op: SwiftOperator.subtract,
                exp: IdentifierExpression(identifier: "a")
            )
            """#,
            macros: testMacros)
    }

    func testMacro_expression_ternary() {
        assertMacroExpansion(#"""
            #ast_expandExpression(a ? b : c)
            """#,
            expandedSource: #"""
            TernaryExpression(
                exp: IdentifierExpression(identifier: "a"),
                ifTrue: IdentifierExpression(identifier: "b"),
                ifFalse: IdentifierExpression(identifier: "c")
            )
            """#,
            macros: testMacros)
    }

    func testMacro_expression_tuple() {
        assertMacroExpansion(#"""
            #ast_expandExpression(())
            #ast_expandExpression((a, b, _: c))
            """#,
            expandedSource: #"""
            TupleExpression(
                elements: []
            )
            TupleExpression(
                elements: [IdentifierExpression(identifier: "a"), IdentifierExpression(identifier: "b"), IdentifierExpression(identifier: "c")]
            )
            """#,
            macros: testMacros)
    }

    func testMacro_expression_typeCheck() {
        assertMacroExpansion(#"""
            #ast_expandExpression(a is B)
            """#,
            expandedSource: #"""
            TypeCheckExpression(
                exp: IdentifierExpression(identifier: "a"),
                type: SwiftType.nominal(NominalSwiftType.typeName("B"))
            )
            """#,
            macros: testMacros)
    }

    func testMacro_expression_tryExpression() {
        assertMacroExpansion(#"""
            #ast_expandExpression(try? a(try! b, try c))
            """#,
            expandedSource: #"""
            TryExpression(
                mode: TryExpression.Mode.optional,
                exp: PostfixExpression(
                exp: IdentifierExpression(identifier: "a"),
                op: FunctionCallPostfix(
                    arguments: [FunctionArgument(
                label: nil,
                expression: TryExpression(
                mode: TryExpression.Mode.forced,
                exp: IdentifierExpression(identifier: "b")
                            )
                        ), FunctionArgument(
                label: nil,
                expression: TryExpression(
                mode: TryExpression.Mode.throwable,
                exp: IdentifierExpression(identifier: "c")
                            )
                        )]
                ).withOptionalAccess(kind: Postfix.OptionalAccessKind.none)
                )
            )
            """#,
            macros: testMacros)
    }

    func testMacro_expression_ifExpression() {
        assertMacroExpansion("""
            #ast_expandExpression(if true { 0 } else { 0 })
            """,
            expandedSource: #"""
            IfExpression(
                clauses: ConditionalClauses(
                clauses: [ConditionalClauseElement(
                expression: ConstantExpression(
                constant: Constant.boolean(true )
                        )
                    )]
                ),
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [ConstantExpression.constant(
                Constant.int(0 , .decimal)
                                )]
                        )]),
                elseBody: .else(CompoundStatement(statements: [ExpressionsStatement(
                expressions: [ConstantExpression.constant(
                Constant.int(0 , .decimal)
                                    )]
                            )]))
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
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [SwitchExpression(
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
                                )]
                        )])
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
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IfExpression(
                clauses: ConditionalClauses(
                clauses: [ConditionalClauseElement(
                expression: IdentifierExpression(identifier: "a")
                                        )]
                                    ),
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "b")]
                                            )]),
                elseBody: nil
                                )]
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
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IfExpression(
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
                                )]
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
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IfExpression(
                clauses: ConditionalClauses(
                clauses: [ConditionalClauseElement(
                expression: IdentifierExpression(identifier: "a")
                                        )]
                                    ),
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "b")]
                                            )]),
                elseBody: .elseIf(IfExpression(
                clauses: ConditionalClauses(
                clauses: [ConditionalClauseElement(
                expression: IdentifierExpression(identifier: "c")
                                                )]
                                            ),
                body: CompoundStatement(statements: [ExpressionsStatement(
                expressions: [IdentifierExpression(identifier: "d")]
                                                    )]),
                elseBody: nil
                                        ))
                                )]
                        )])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_firstExpressionIn() {
        assertMacroExpansion(#"""
            #ast_expandExpression(firstExpressionIn: { (a: String, b: Int) in
                a.count + b
            })
            """#,
            expandedSource: #"""
            BinaryExpression(
                lhs: PostfixExpression(
                exp: IdentifierExpression(identifier: "a"),
                op: MemberPostfix(
                    name: "count",
                    argumentNames: nil
                ).withOptionalAccess(kind: Postfix.OptionalAccessKind.none)
                ),
                op: SwiftOperator.add,
                rhs: IdentifierExpression(identifier: "b")
            )
            """#,
            macros: testMacros)
    }

    // MARK: - Diagnostics tests

    func testMacro_diagnostic_blockLiteral_signature_noReturnType() {
        assertDiagnostics("""
            #ast_expandExpression(a = { (b: Int) in b })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("a = { (b: Int) in b }"))
            """#, [
                DiagnosticSpec(
                    message: "Blocks that provide a signature must provide a return type.",
                    line: 1,
                    column: 29
                )
            ])
    }

    func testMacro_diagnostic_blockLiteral_signature_simpleInput() {
        assertDiagnostics("""
            #ast_expandExpression(a = { _ -> Void in b })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("a = { _ -> Void in b }"))
            """#, [
                DiagnosticSpec(
                    message: "Blocks that provide a signature must provide a parameter set with labels and types.",
                    line: 1,
                    column: 29
                )
            ])
    }

    func testMacro_diagnostic_blockLiteral_signature_secondName() {
        assertDiagnostics("""
            #ast_expandExpression(a = { (_ b: Int) -> Void in b })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("a = { (_ b: Int) -> Void in b }"))
            """#, [
                DiagnosticSpec(
                    message: "BlockLiteralExpression doesn't support parameters with second names.",
                    line: 1,
                    column: 32
                )
            ])
    }

    func testMacro_diagnostic_blockLiteral_signature_noExplicitType() {
        assertDiagnostics("""
            #ast_expandExpression(a = { (b: Int, c) -> Void in b })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("a = { (b: Int, c) -> Void in b }"))
            """#, [
                DiagnosticSpec(
                    message: "BlockLiteralExpression doesn't support parameters with no explicit type.",
                    line: 1,
                    column: 38
                )
            ])
    }

    func testMacro_diagnostic_cast_forceCast() {
        assertDiagnostics("""
            #ast_expandExpression(a as! B)
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("a as! B"))
            """#, [
                DiagnosticSpec(
                    message: "CastExpression does not currently support forced-cast expressions.",
                    line: 1,
                    column: 27
                )
            ])
    }

    func testMacro_diagnostic_identifier_argumentNames() {
        assertDiagnostics("""
            #ast_expandExpression(a(b:_:))
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("a(b:_:)"))
            """#, [
                DiagnosticSpec(
                    message: "Argument names of DeclReferenceExprSyntax unimplemented",
                    line: 1,
                    column: 24
                )
            ])
    }

    func testMacro_diagnostic_postfix_member_implicitBase() {
        assertDiagnostics("""
            #ast_expandExpression(.a)
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext(".a"))
            """#, [
                DiagnosticSpec(
                    message: "PostfixExpression does not currently support implicit base postfix member accesses.",
                    line: 1,
                    column: 23
                )
            ])
    }

    func testMacro_diagnostic_postfix_function_trailingClosure() {
        assertDiagnostics("""
            #ast_expandExpression(a.b(c){ d })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("a.b(c){ d }"))
            """#, [
                DiagnosticSpec(
                    message: "Trailing closure parameter conversion not yet implemented.",
                    line: 1,
                    column: 29
                )
            ])
    }

    func testMacro_diagnostic_postfix_subscript_trailingClosure() {
        assertDiagnostics("""
            #ast_expandExpression(a.b[c]{ d })
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("a.b[c]{ d }"))
            """#, [
                DiagnosticSpec(
                    message: "Trailing closure parameter conversion not yet implemented.",
                    line: 1,
                    column: 29
                )
            ])
    }

    func testMacro_diagnostic_postfix_multipleNestedOptionals() {
        assertDiagnostics("""
            #ast_expandExpression(a?!?.b)
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("a?!?.b"))
            """#, [
                DiagnosticSpec(
                    message: "Multiple nested optional access expressions are not supported by SwiftAST.",
                    line: 1,
                    column: 23
                )
            ])
    }

    func testMacro_diagnostic_tuple_labels() {
        assertDiagnostics("""
            #ast_expandExpression((a, b: b))
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("(a, b: b)"))
            """#, [
                DiagnosticSpec(
                    message: "TupleExpression does not currently support tuple labels.",
                    line: 1,
                    column: 27
                )
            ])
    }

    func testMacro_diagnostic_unrecognizedOperator() {
        assertDiagnostics("""
            #ast_expandExpression(a +-+ b)
            """,
            expandedSource: #"""
            UnknownExpression(context: UnknownASTContext("a +-+ b"))
            """#, [
                DiagnosticSpec(
                    message: "Invalid SwiftOperator token conversion",
                    line: 1,
                    column: 25
                )
            ])
    }

    func testMacro_diagnostic_firstExpressionIn_nonBlockArgument() {
        assertDiagnostics("""
            #ast_expandExpression(firstExpressionIn: true)
            """,
            expandedSource: #"""
            #ast_expandExpression(firstExpressionIn: true)
            """#, [
                DiagnosticSpec(
                    message: "Expected 'firstExpressionIn' argument to be a closure literal.",
                    line: 1,
                    column: 1
                ),
            ])
    }

    func testMacro_diagnostic_firstExpressionIn_nonExpressionFirstArgument() {
        assertDiagnostics("""
            #ast_expandExpression(firstExpressionIn: { })
            #ast_expandExpression(firstExpressionIn: { return })
            """,
            expandedSource: #"""
            #ast_expandExpression(firstExpressionIn: { })
            #ast_expandExpression(firstExpressionIn: { return })
            """#, [
                DiagnosticSpec(
                    message: "Expected 'firstExpressionIn' closure to contain an expression as its first statement.",
                    line: 1,
                    column: 1
                ),
                DiagnosticSpec(
                    message: "Expected 'firstExpressionIn' closure to contain an expression as its first statement.",
                    line: 2,
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
