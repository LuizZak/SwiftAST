import SwiftSyntax

enum SwiftASTConverter {
    /// The static constructor for `SwiftType.void`, as an expression syntax.
    static let swiftTypeVoid: ExprSyntax = "SwiftType.void"

    /// The static constructor for `Ownership.strong`, as an expression syntax
    static let ownershipStrong: ExprSyntax = "Ownership.strong"

    static func stringLiteral(_ string: String) -> StringLiteralExprSyntax {
        return .init(content: string)
    }

    static func stringLiteral(_ token: TokenSyntax) -> StringLiteralExprSyntax {
        return stringLiteral(token.trimmed.description)
    }
}
