import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
import SwiftBasicFormat

public struct SwiftASTExpressionMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {

        let impl = SwiftASTExpressionMacroImplementation(
            node: node,
            context: context
        )

        return try runImplementation(impl)
    }

    private static func runImplementation(
        _ impl: SwiftASTExpressionMacroImplementation
    ) throws -> ExprSyntax {

        do {
            return try impl.expand()
        } catch MacroError.diagnostic(let diag) {
            impl.context.diagnose(diag)
            let debugMessage = impl.node.arguments.description.debugDescription
            return "UnknownExpression(context: UnknownASTContext(\(raw: debugMessage)))"
        } catch {
            throw error
        }
    }
}

class SwiftASTExpressionMacroImplementation {
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
        guard let inputExpression = node.arguments.first?.expression else {
            throw MacroError.message("Expected expression as first argument of macro")
        }

        let result = try SwiftASTConverter.convertExpression(inputExpression)

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
