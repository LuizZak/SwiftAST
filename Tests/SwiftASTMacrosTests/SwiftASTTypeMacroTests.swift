import XCTest
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport

@testable import SwiftASTMacros

class SwiftASTTypeMacroTests: XCTestCase {
    let testMacros: [String: Macro.Type] = [
        "ast_expandType": SwiftASTTypeMacro.self,
    ]

    func testMacro_nested() {
        assertMacroExpansion("""
            #ast_expandType<MyType.Inner>()
            #ast_expandType<MyType.Inner<Int>>()
            """,
            expandedSource: #"""
            SwiftType.nested(NestedSwiftType.fromCollection([NominalSwiftType.typeName("Inner"), NominalSwiftType.typeName("MyType")]))
            SwiftType.nested(NestedSwiftType.fromCollection([NominalSwiftType.generic(
                "Inner",
                parameters: [SwiftType.nominal(NominalSwiftType.typeName("Int"))]
                        ), NominalSwiftType.typeName("MyType")]))
            """#,
            macros: testMacros)
    }

    func testMacro_nominal() {
        assertMacroExpansion("""
            #ast_expandType<MyType>()
            #ast_expandType<MyType<Int>>()
            """,
            expandedSource: #"""
            SwiftType.nominal(NominalSwiftType.typeName("MyType"))
            SwiftType.nominal(NominalSwiftType.generic(
                "MyType",
                parameters: [SwiftType.nominal(NominalSwiftType.typeName("Int"))]
                ))
            """#,
            macros: testMacros)
    }

    func testMacro_protocolComposition() {
        assertMacroExpansion("""
            #ast_expandType<Type1 & Type2>()
            #ast_expandType<Type1<Int> & Type2.Inner>()
            """,
            expandedSource: #"""
            SwiftType.protocolComposition(ProtocolCompositionSwiftType.fromCollection([ProtocolCompositionComponent.nominal(NominalSwiftType.typeName("Type1")), ProtocolCompositionComponent.nominal(NominalSwiftType.typeName("Type2"))]))
            SwiftType.protocolComposition(ProtocolCompositionSwiftType.fromCollection([ProtocolCompositionComponent.nominal(NominalSwiftType.generic(
                "Type1",
                parameters: [SwiftType.nominal(NominalSwiftType.typeName("Int"))]
                            )), ProtocolCompositionComponent.nested(NestedSwiftType.fromCollection([NominalSwiftType.typeName("Inner"), NominalSwiftType.typeName("Type2")]))]))
            """#,
            macros: testMacros)
    }

    func testMacro_tuple() {
        assertMacroExpansion("""
            #ast_expandType<()>()
            #ast_expandType<(Type1)>()
            #ast_expandType<(Type1, Type2)>()
            """,
            expandedSource: #"""
            SwiftType.tuple(TupleSwiftType.empty)
            SwiftType.nominal(NominalSwiftType.typeName("Type1"))
            SwiftType.tuple(TupleSwiftType.types([SwiftType.nominal(NominalSwiftType.typeName("Type1")), SwiftType.nominal(NominalSwiftType.typeName("Type2"))]))
            """#,
            macros: testMacros)
    }

    func testMacro_block() {
        assertMacroExpansion("""
            #ast_expandType<() -> Void>()
            #ast_expandType<(Int, Double) -> String>()
            #ast_expandType<@escaping () -> Void>()
            #ast_expandType<@autoclosure () -> Void>()
            #ast_expandType<@convention(c) () -> Void>()
            #ast_expandType<@convention(block) () -> Void>()
            """,
            expandedSource: #"""
            SwiftType.block(BlockSwiftType(
                returnType: SwiftType.nominal(NominalSwiftType.typeName("Void")),
                parameters: []
                ))
            SwiftType.block(BlockSwiftType(
                returnType: SwiftType.nominal(NominalSwiftType.typeName("String")),
                parameters: [SwiftType.nominal(NominalSwiftType.typeName("Int")), SwiftType.nominal(NominalSwiftType.typeName("Double"))]
                ))
            SwiftType.block(
                BlockSwiftType(
                    returnType: SwiftType.nominal(NominalSwiftType.typeName("Void")),
                    parameters: []
                ).addingAttributes([BlockTypeAttribute.escaping])
            )
            SwiftType.block(
                BlockSwiftType(
                    returnType: SwiftType.nominal(NominalSwiftType.typeName("Void")),
                    parameters: []
                ).addingAttributes([BlockTypeAttribute.autoclosure])
            )
            SwiftType.block(
                BlockSwiftType(
                    returnType: SwiftType.nominal(NominalSwiftType.typeName("Void")),
                    parameters: []
                ).addingAttributes([BlockTypeAttribute.convention(BlockTypeAttribute.Convention.c)])
            )
            SwiftType.block(
                BlockSwiftType(
                    returnType: SwiftType.nominal(NominalSwiftType.typeName("Void")),
                    parameters: []
                ).addingAttributes([BlockTypeAttribute.convention(BlockTypeAttribute.Convention.block)])
            )
            """#,
            macros: testMacros)
    }

    func testMacro_metatype() {
        assertMacroExpansion("""
            #ast_expandType<Type1.Type>()
            """,
            expandedSource: #"""
            SwiftType.metatype(for: SwiftType.nominal(NominalSwiftType.typeName("Type1")))
            """#,
            macros: testMacros)
    }

    func testMacro_optional() {
        assertMacroExpansion("""
            #ast_expandType<Int?>()
            """,
            expandedSource: #"""
            SwiftType.optional(SwiftType.nominal(NominalSwiftType.typeName("Int")))
            """#,
            macros: testMacros)
    }

    func testMacro_implicitlyUnwrappedOptional() {
        assertMacroExpansion("""
            #ast_expandType<Int!>()
            """,
            expandedSource: #"""
            SwiftType.implicitUnwrappedOptional(SwiftType.nominal(NominalSwiftType.typeName("Int")))
            """#,
            macros: testMacros)
    }

    func testMacro_array() {
        assertMacroExpansion("""
            #ast_expandType<[Int]>()
            """,
            expandedSource: #"""
            SwiftType.array(SwiftType.nominal(NominalSwiftType.typeName("Int")))
            """#,
            macros: testMacros)
    }

    func testMacro_dictionary() {
        assertMacroExpansion("""
            #ast_expandType<[Int: String]>()
            """,
            expandedSource: #"""
            SwiftType.dictionary(key: SwiftType.nominal(NominalSwiftType.typeName("Int")), value: SwiftType.nominal(NominalSwiftType.typeName("String")))
            """#,
            macros: testMacros)
    }

    // MARK: - Diagnostics tests

    func testMacro_diagnostics_unsupportedTypeSpecifier() {
        assertDiagnostics("""
            #ast_expandType<inout Int>()
            """,
            expandedSource: #"""
            SwiftType.errorType
            """#, [
                DiagnosticSpec(
                    message: "SwiftType does not support type specifiers.",
                    line: 1,
                    column: 17
                )
            ])
    }

    func testMacro_diagnostics_unsupportedAttributedType() {
        assertDiagnostics("""
            #ast_expandType<@attribute Int>()
            """,
            expandedSource: #"""
            SwiftType.errorType
            """#, [
                DiagnosticSpec(
                    message: "SwiftType does not support attributes in the given type.",
                    line: 1,
                    column: 28
                )
            ])
    }

    func testMacro_diagnostics_nested_unsupportedBaseType() {
        assertDiagnostics("""
            #ast_expandType<[Int].Element>()
            """,
            expandedSource: #"""
            SwiftType.errorType
            """#, [
                DiagnosticSpec(
                    message: "Unsupported base type in member type syntax. Expected: IdentifierTypeSyntax or MemberTypeSyntax",
                    line: 1,
                    column: 17
                )
            ])
    }

    func testMacro_diagnostics_block_unsupportedAttribute() {
        assertDiagnostics("""
            #ast_expandType<@attribute () -> Void>()
            """,
            expandedSource: #"""
            SwiftType.errorType
            """#, [
                DiagnosticSpec(
                    message: "SwiftType only supports @autoclosure, @escaping, @convention(c), @convention(block) function type annotations.",
                    line: 1,
                    column: 17
                )
            ])
    }

    func testMacro_diagnostics_block_effectSpecifiers() {
        assertDiagnostics("""
            #ast_expandType<() throws -> Void>()
            """,
            expandedSource: #"""
            SwiftType.errorType
            """#, [
                DiagnosticSpec(
                    message: "BlockSwiftType does not currently support effect specifiers of function type syntaxes.",
                    line: 1,
                    column: 17
                )
            ])
    }

    func testMacro_diagnostics_block_argument_firstName() {
        assertDiagnostics("""
            #ast_expandType<(a: A) -> Void>()
            """,
            expandedSource: #"""
            SwiftType.errorType
            """#, [
                DiagnosticSpec(
                    message: "BlockSwiftType does not currently support argument names of function type syntaxes.",
                    line: 1,
                    column: 18
                )
            ])
    }

    func testMacro_diagnostics_block_argument_inout() {
        assertDiagnostics("""
            #ast_expandType<(inout A) -> Void>()
            """,
            expandedSource: #"""
            SwiftType.errorType
            """#, [
                DiagnosticSpec(
                    message: "SwiftType does not support type specifiers.",
                    line: 1,
                    column: 18
                )
            ])
    }

    func testMacro_diagnostics_block_argument_ellipsis() {
        assertDiagnostics("""
            #ast_expandType<(A...) -> Void>()
            """,
            expandedSource: #"""
            SwiftType.errorType
            """#, [
                DiagnosticSpec(
                    message: "BlockSwiftType does not currently support ellipsis of function type syntaxes.",
                    line: 1,
                    column: 19
                )
            ])
    }

    func testMacro_diagnostics_protocolComposition_unsupportedType() {
        assertDiagnostics("""
            #ast_expandType<A & [B]>()
            """,
            expandedSource: #"""
            SwiftType.errorType
            """#, [
                DiagnosticSpec(
                    message: "Unsupported type in protocol composition type. Expected: IdentifierTypeSyntax or MemberTypeSyntax",
                    line: 1,
                    column: 21
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
