import SwiftSyntax

// Note: Must ideally be kept 1-to-1 with SwiftAST's own SwiftOperator structure.
enum _SwiftOperator: String, Equatable {
    case add = "+"
    case subtract = "-"
    case multiply = "*"
    case divide = "/"
    case mod = "%"
    case addAssign = "+="
    case subtractAssign = "-="
    case multiplyAssign = "*="
    case divideAssign = "/="
    case modAssign = "%="
    case negate = "!"
    case and = "&&"
    case or = "||"
    case bitwiseAnd = "&"
    case bitwiseOr = "|"
    case bitwiseXor = "^"
    case bitwiseNot = "~"
    case bitwiseShiftLeft = "<<"
    case bitwiseShiftRight = ">>"
    case bitwiseAndAssign = "&="
    case bitwiseOrAssign = "|="
    case bitwiseXorAssign = "^="
    case bitwiseNotAssign = "~="
    case bitwiseShiftLeftAssign = "<<="
    case bitwiseShiftRightAssign = ">>="
    case lessThan = "<"
    case lessThanOrEqual = "<="
    case greaterThan = ">"
    case greaterThanOrEqual = ">="
    case assign = "="
    case equals = "=="
    case unequals = "!="
    case identityEquals = "==="
    case identityUnequals = "!=="
    case nullCoalesce = "??"
    case openRange = "..<"
    case closedRange = "..."

    var isAssignment: Bool {
        switch self {
        case .assign, .modAssign, .addAssign, .divideAssign, .multiplyAssign,
            .subtractAssign, .bitwiseOrAssign, .bitwiseAndAssign, .bitwiseNotAssign,
            .bitwiseXorAssign, .bitwiseShiftLeftAssign, .bitwiseShiftRightAssign:
            return true

        default:
            return false
        }
    }

    /// Returns the name of this operator in the `SwiftOperator` enumeration type
    /// from SwiftAST.
    var name: String {
        switch self {
        case .add: "add"
        case .subtract: "subtract"
        case .multiply: "multiply"
        case .divide: "divide"
        case .mod: "mod"
        case .addAssign: "addAssign"
        case .subtractAssign: "subtractAssign"
        case .multiplyAssign: "multiplyAssign"
        case .divideAssign: "divideAssign"
        case .modAssign: "modAssign"
        case .negate: "negate"
        case .and: "and"
        case .or: "or"
        case .bitwiseAnd: "bitwiseAnd"
        case .bitwiseOr: "bitwiseOr"
        case .bitwiseXor: "bitwiseXor"
        case .bitwiseNot: "bitwiseNot"
        case .bitwiseShiftLeft: "bitwiseShiftLeft"
        case .bitwiseShiftRight: "bitwiseShiftRight"
        case .bitwiseAndAssign: "bitwiseAndAssign"
        case .bitwiseOrAssign: "bitwiseOrAssign"
        case .bitwiseXorAssign: "bitwiseXorAssign"
        case .bitwiseNotAssign: "bitwiseNotAssign"
        case .bitwiseShiftLeftAssign: "bitwiseShiftLeftAssign"
        case .bitwiseShiftRightAssign: "bitwiseShiftRightAssign"
        case .lessThan: "lessThan"
        case .lessThanOrEqual: "lessThanOrEqual"
        case .greaterThan: "greaterThan"
        case .greaterThanOrEqual: "greaterThanOrEqual"
        case .assign: "assign"
        case .equals: "equals"
        case .unequals: "unequals"
        case .identityEquals: "identityEquals"
        case .identityUnequals: "identityUnequals"
        case .nullCoalesce: "nullCoalesce"
        case .openRange: "openRange"
        case .closedRange: "closedRange"
        }
    }

    var asSwiftOperatorExpr: ExprSyntax {
        "SwiftOperator.\(raw: self.name)"
    }

    /// Attempts to instantiate a `_SwiftOperator` from a given token syntax.
    ///
    /// Throws, if no operator could be recognized.
    static func tryFrom(_ token: TokenSyntax) throws -> Self {
        let string = token.trimmed.description
        guard let result = Self(rawValue: string) else {
            throw token.ext_error(message: "Invalid SwiftOperator token conversion")
        }

        return result
    }

    /// Attempts to instantiate a `_SwiftOperator` from a given expression syntax.
    ///
    /// Throws, if no operator could be recognized.
    static func tryFrom(_ expr: ExprSyntax) throws -> Self {
        let string = expr.trimmed.description
        guard let result = Self(rawValue: string) else {
            throw expr.ext_error(message: "Invalid SwiftOperator token conversion")
        }

        return result
    }
}
