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
    static let arg_firstExpressionIn = "firstExpressionIn"

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
        guard
            let inputExpression = try firstArgumentInExpression() ?? node.arguments.first?.expression
        else {
            throw MacroError.message("Expected expression as first argument of macro")
        }

        let result = try SwiftASTConverter.convertExpression(inputExpression)

        let formatter = basicFormat()
        if let formatted = result.formatted(using: formatter).as(ExprSyntax.self) {
            return formatted
        }

        return result
    }

    func firstArgumentInExpression() throws -> ExprSyntax? {
        for argument in node.arguments {
            guard let label = argument.label?.trimmed.description else {
                continue
            }

            switch label {
            case Self.arg_firstExpressionIn:
                guard let value = argument.expression.as(ClosureExprSyntax.self) else {
                    throw MacroError.message("""
                    Expected '\(Self.arg_firstExpressionIn)' argument to be a closure literal.
                    """)
                }
                guard
                    let firstItem = value.statements.first,
                    case .expr(let firstExpression) = firstItem.item
                else {
                    throw MacroError.message("""
                    Expected '\(Self.arg_firstExpressionIn)' closure to contain an expression as its first statement.
                    """)
                }

                return firstExpression
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
