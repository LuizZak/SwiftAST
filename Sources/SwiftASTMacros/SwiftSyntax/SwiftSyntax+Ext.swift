import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftDiagnostics

extension SyntaxProtocol {
    /// Helper for generating targeted macro errors from a specific syntax node
    /// from source code.
    func ext_error(
        message: String
    ) -> MacroError {
        return MacroError.diagnostic(
            ext_errorDiagnostic(message: message)
        )
    }

    /// Helper for generating targeted macro diagnostic error messages from a
    /// specific syntax node from source code.
    func ext_errorDiagnostic(
        message: String
    ) -> Diagnostic {
        return Diagnostic(
            node: self,
            message: MacroExpansionErrorMessage(message)
        )
    }

    /// Helper for generating targeted macro diagnostic error messages from a
    /// specific syntax node from source code.
    func ext_errorDiagnostic<S: SyntaxProtocol>(
        message: String,
        highlights: (any Sequence<S>)?
    ) -> Diagnostic {
        let highlights = highlights?.map(Syntax.init(_:))

        return Diagnostic(
            node: self,
            message: MacroExpansionErrorMessage(message),
            highlights: (highlights == nil || highlights?.count == 0) ? nil : highlights
        )
    }

    /// Helper for generating targeted macro diagnostic warning messages from a
    /// specific syntax node from source code.
    func ext_warningDiagnostic(
        message: String
    ) -> Diagnostic {
        return Diagnostic(
            node: self,
            message: MacroExpansionWarningMessage(message)
        )
    }

    /// Extracts all leading trivia on this syntax that is of doc comment
    /// line/block type.
    /// The trivia only includes the comments themselves, with no leading/trailing
    /// whitespace, except for whitespace between the comments, if more than one
    /// comment exists.
    func ext_docComments() -> Trivia {
        func isDocComment(_ piece: TriviaPiece) -> Bool {
            switch piece {
            case .docBlockComment(let string), .docLineComment(let string):
                return !string.isEmpty
            default:
                return false
            }
        }

        guard let startIndex = leadingTrivia.firstIndex(where: isDocComment) else {
            return Trivia()
        }
        guard let endIndex = Array(leadingTrivia).lastIndex(where: isDocComment) else {
            return Trivia()
        }

        return Trivia(pieces: leadingTrivia[startIndex...endIndex])
    }

    func ext_notImplementedError(_ function: StaticString = #function) -> MacroError {
        self.ext_error(message: "\(function): Not implemented")
    }
}
