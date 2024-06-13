import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
import SwiftBasicFormat

public struct SwiftASTStatementsMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {

        let impl = SwiftASTStatementsMacroImplementation(
            node: node,
            context: context
        )

        return try runImplementation(impl)
    }

    private static func runImplementation(
        _ impl: SwiftASTStatementsMacroImplementation
    ) throws -> ExprSyntax {

        do {
            return try impl.expand()
        } catch MacroError.diagnostic(let diag) {
            impl.context.diagnose(diag)
            let debugMessage = impl.node.arguments.description.debugDescription
            return "UnknownStatement(context: UnknownASTContext(\(raw: debugMessage)))"
        } catch {
            throw error
        }
    }
}

class SwiftASTStatementsMacroImplementation {
    static let arg_singleStatement = "singleStatement"

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
        let inputClosure = try closureArgument()
        let singleExpression = try singleExpressionArgument() ?? false

        let statements = inputClosure.statements

        let result: ExprSyntax
        if singleExpression {
            guard let firstStatement = statements.first else {
                throw MacroError.message("""
                Expected at least one statement within the closure with '\(Self.arg_singleStatement)'
                """)
            }

            result = try SwiftASTConverter.convertStatement(firstStatement)
        } else {
            result = try SwiftASTConverter.convertCompound(statements)
        }

        let formatter = basicFormat()
        if let formatted = result.formatted(using: formatter).as(ExprSyntax.self) {
            return formatted
        }

        return result
    }

    func singleExpressionArgument() throws -> Bool? {
        for argument in node.arguments {
            guard let label = argument.label?.trimmed.description else {
                continue
            }

            switch label {
            case Self.arg_singleStatement:
                guard let value = argument.expression.as(BooleanLiteralExprSyntax.self) else {
                    throw MacroError.message("""
                    Expected '\(Self.arg_singleStatement)' argument to be a boolean literal value.
                    """)
                }

                return value.literal.tokenKind == .keyword(.true)
            default:
                throw MacroError.message("""
                Unrecognized argument label '\(label)'
                """)
            }
        }

        return nil
    }

    func closureArgument() throws -> ClosureExprSyntax {
        for argument in node.arguments where argument.label == nil {
            guard let inputClosure = argument.expression.as(ClosureExprSyntax.self) else {
                throw MacroError.message("Expected a closure expression")
            }

            return inputClosure
        }

        throw MacroError.message("Expected a closure expression")
    }

    func basicFormat() -> BasicFormat {
        BasicFormat(indentationWidth: .spaces(4))
    }
}
