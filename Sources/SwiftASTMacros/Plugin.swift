import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct Macros: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SwiftASTExpressionMacro.self,
        SwiftASTStatementsMacro.self,
        SwiftASTTypeMacro.self,
    ]
}
