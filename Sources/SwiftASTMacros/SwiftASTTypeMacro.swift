import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
import SwiftBasicFormat

public struct SwiftASTTypeMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {

        let impl = SwiftASTTypeMacroImplementation(
            node: node,
            context: context
        )

        return try runImplementation(impl)
    }

    private static func runImplementation(
        _ impl: SwiftASTTypeMacroImplementation
    ) throws -> ExprSyntax {

        do {
            return try impl.expand()
        } catch MacroError.diagnostic(let diag) {
            impl.context.diagnose(diag)
            return "SwiftType.errorType"
        } catch {
            throw error
        }
    }
}

class SwiftASTTypeMacroImplementation {
    let node: any FreestandingMacroExpansionSyntax
    let context: any MacroExpansionContext

    init(
        node: some FreestandingMacroExpansionSyntax,
        context: some MacroExpansionContext
    ) {
        self.node = node
        self.context = context
    }

    func expand() throws -> ExprSyntax {
        guard let inputType = node.genericArgumentClause?.arguments.first else {
            throw MacroError.message("Expected a generic type in the macro declaration")
        }

        let result = try SwiftASTConverter.convertType(inputType.argument)

        let formatter = basicFormat()
        if let formatted = result.formatted(using: formatter).as(ExprSyntax.self) {
            return formatted
        }

        return result
    }

    func basicFormat() -> BasicFormat {
        BasicFormat(indentationWidth: .spaces(4))
    }
}
