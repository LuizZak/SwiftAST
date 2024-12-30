/// A pattern for pattern-matching
public enum Pattern: Codable, Equatable, Hashable, ExpressionComponent {
    /// An identifier pattern
    case identifier(String, TypeAnnotation? = nil)

    /// An expression pattern
    case expression(Expression)

    /// A tuple pattern
    indirect case tuple([Pattern], TypeAnnotation? = nil)

    /// A value-binding pattern.
    ///
    /// `constant` specifies whether the values bind to a constant (`let`) or
    /// not (`var`).
    indirect case valueBindingPattern(constant: Bool = true, Pattern)

    /// A type-cast pattern that matches a pattern against a type.
    indirect case asType(Pattern, SwiftType)

    /// An optional pattern match that unwraps optional values.
    indirect case optional(Pattern)

    /// A wildcard pattern (or `_`).
    case wildcard(TypeAnnotation? = nil)

    /// Simplifies patterns that feature 1-item tuples (i.e. `(<item>)`) by
    /// unwrapping the inner patterns.
    ///
    /// Does not simplify tuple patterns with type annotations
    public var simplified: Pattern {
        switch self {
        case .tuple(let pt, nil) where pt.count == 1:
            return pt[0].simplified

        default:
            return self
        }
    }

    /// Returns `true` if `self` of one of its sub patterns is a `Pattern.valueBindingPattern`.
    public var hasBindings: Bool {
        switch self {
        case .valueBindingPattern:
            return true

        case .tuple(let patterns, _):
            return patterns.contains(where: \.hasBindings)

        case .asType(let pattern, _), .optional(let pattern):
            return pattern.hasBindings

        case .expression, .identifier, .wildcard:
            return false
        }
    }

    /// Returns a list of sub-expressions contained within this pattern.
    public var subExpressions: [Expression] {
        switch self {
        case .expression(let exp):
            return [exp]

        case .tuple(let tuple, _):
            return tuple.flatMap { $0.subExpressions }

        case .asType(let inner, _),
            .valueBindingPattern(_, let inner),
            .optional(let inner):
            return inner.subExpressions

        case .identifier, .wildcard:
            return []
        }
    }

    /// Returns a shallow list of sub-patterns contained within this pattern.
    internal var subPatterns: [Self] {
        switch self {
        case .tuple(let patterns, _):
            return patterns

        case .asType(let pattern, _),
            .valueBindingPattern(_, let pattern),
            .optional(let pattern):
            return [pattern]

        case .expression, .identifier, .wildcard:
            return []
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let discriminator = try container.decode(String.self, forKey: .discriminator)

        switch discriminator {
        case "identifier":
            try self = .identifier(
                container.decode(String.self, forKey: .payload0),
                container.decodeIfPresent(TypeAnnotation.self, forKey: .payload1)
            )

        case "expression":
            try self = .expression(container.decodeExpression(forKey: .payload0))

        case "tuple":
            try self = .tuple(
                container.decode([Pattern].self, forKey: .payload0),
                container.decodeIfPresent(TypeAnnotation.self, forKey: .payload1)
            )

        case "asType":
            try self = .asType(
                container.decode(Pattern.self, forKey: .payload0),
                container.decode(SwiftType.self, forKey: .payload1)
            )

        case "valueBindingPattern":
            try self = .valueBindingPattern(
                constant: container.decode(Bool.self, forKey: .payload0),
                container.decode(Pattern.self, forKey: .payload1)
            )

        case "optional":
            try self = .optional(
                container.decode(Pattern.self, forKey: .payload0)
            )

        case "wildcard":
            try self = .wildcard(container.decodeIfPresent(TypeAnnotation.self, forKey: .payload0))

        default:
            throw DecodingError.dataCorruptedError(
                forKey: CodingKeys.discriminator,
                in: container,
                debugDescription: "Invalid discriminator tag \(discriminator)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .identifier(let ident, let type):
            try container.encode("identifier", forKey: .discriminator)
            try container.encode(ident, forKey: .payload0)
            try container.encodeIfPresent(type, forKey: .payload1)

        case .expression(let exp):
            try container.encode("expression", forKey: .discriminator)
            try container.encodeExpression(exp, forKey: .payload0)

        case .tuple(let pattern, let type):
            try container.encode("tuple", forKey: .discriminator)
            try container.encode(pattern, forKey: .payload0)
            try container.encodeIfPresent(type, forKey: .payload1)

        case .asType(let pattern, let type):
            try container.encode("asType", forKey: .discriminator)
            try container.encode(pattern, forKey: .payload0)
            try container.encode(type, forKey: .payload1)

        case .valueBindingPattern(let constant, let pattern):
            try container.encode("valueBindingPattern", forKey: .discriminator)
            try container.encode(constant, forKey: .payload0)
            try container.encode(pattern, forKey: .payload1)

        case .optional(let pattern):
            try container.encode("optional", forKey: .discriminator)
            try container.encode(pattern, forKey: .payload0)

        case .wildcard(let type):
            try container.encode("wildcard", forKey: .discriminator)
            try container.encodeIfPresent(type, forKey: .payload0)
        }
    }

    public static func fromExpressions(_ expr: [Expression]) -> Pattern {
        if expr.count == 1 {
            return .expression(expr[0])
        }

        return .tuple(expr.map { .expression($0) })
    }

    @inlinable
    public func copy() -> Pattern {
        switch self {
        case .identifier, .wildcard:
            return self

        case .expression(let exp):
            return .expression(exp.copy())

        case .tuple(let patterns, let type):
            return .tuple(patterns.map { $0.copy() }, type)

        case .asType(let pattern, let type):
            return .asType(pattern.copy(), type)

        case .valueBindingPattern(let constant, let pattern):
            return .valueBindingPattern(constant: constant, pattern.copy())

        case .optional(let pattern):
            return .optional(pattern.copy())
        }
    }

    internal func setParent(_ node: SyntaxNode?) {
        switch self {
        case .expression(let exp):
            exp.parent = node

        case .tuple(let tuple, _):
            tuple.forEach { $0.setParent(node) }

        case .asType(let pattern, _):
            pattern.setParent(node)

        case .valueBindingPattern(_, let pattern), .optional(let pattern):
            pattern.setParent(node)

        case .identifier, .wildcard:
            break
        }
    }

    internal func collect(expressions: inout [SyntaxNode]) {
        switch self {
        case .expression(let exp):
            expressions.append(exp)

        case .tuple(let tuple, _):
            tuple.forEach { $0.collect(expressions: &expressions) }

        case .asType(let pattern, _):
            pattern.collect(expressions: &expressions)

        case .valueBindingPattern(_, let pattern), .optional(let pattern):
            pattern.collect(expressions: &expressions)

        case .identifier, .wildcard:
            break
        }
    }

    /// Returns a sub-pattern in this pattern on a specified pattern location.
    ///
    /// - Parameter location: Location of pattern to search
    /// - Returns: `self`, if `location == .self`, or a sub-pattern within.
    /// Returns `nil`, if the location is invalid within this pattern.
    func subPattern(at location: PatternLocation) -> Pattern? {
        switch (location, self) {
        case (.self, _):
            return self

        case let (.tuple(index, subLocation), .tuple(subPatterns, _)):
            if index >= subPatterns.count {
                return nil
            }

            return subPatterns[index].subPattern(at: subLocation)

        case let (.asType(subLocation), .asType(subPattern, _)):
            return subPattern.subPattern(at: subLocation)

        case let (.valueBindingPattern(subLocation), .valueBindingPattern(_, subPattern)):
            return subPattern.subPattern(at: subLocation)

        case let (.optional(subLocation), .optional(subPattern)):
            return subPattern.subPattern(at: subLocation)

        default:
            return nil
        }
    }

    public enum CodingKeys: String, CodingKey {
        case discriminator
        case payload0
        case payload1
    }

    /// A type annotation that might appear in a pattern.
    public struct TypeAnnotation: Equatable, Hashable, Codable, CustomStringConvertible {
        public var type: SwiftType

        public var description: String {
            ": \(type)"
        }

        public init(type: SwiftType) {
            self.type = type
        }
    }
}

extension Pattern: CustomStringConvertible {
    public var description: String {
        switch self.simplified {
        case .tuple(let tups, let type):
            var base = "(" + tups.map(\.description).joined(separator: ", ") + ")"
            if let type {
                base += type.description
            }

            return base

        case .expression(let exp):
            return exp.description

        case .identifier(let ident, let type):
            var base = ident
            if let type {
                base += type.description
            }

            return base

        case .asType(let pattern, let type):
            return "\(pattern) as \(type)"

        case .valueBindingPattern(true, let pattern):
            return "let \(pattern)"

        case .valueBindingPattern(false, let pattern):
            return "var \(pattern)"

        case .optional(let pattern):
            return "\(pattern)?"

        case .wildcard(let type):
            var base = "_"
            if let type {
                base += type.description
            }

            return base
        }
    }
}

/// Allows referencing a location within a pattern for an identifier, an
/// expression or a tuple-pattern.
public enum PatternLocation: Hashable {
    /// The root pattern itself
    case `self`

    /// The tuple within the pattern, at a given index, with a given nested
    /// sub-pattern location.
    indirect case tuple(index: Int, pattern: PatternLocation)

    /// The 'as Type' pattern within the pattern, with a given nested sub-pattern
    /// location.
    indirect case asType(pattern: PatternLocation)

    /// The sub pattern within a value binding pattern, with a given nested
    /// sub-pattern location.
    indirect case valueBindingPattern(pattern: PatternLocation)

    /// The sub pattern within an optional pattern, with a given nested sub-pattern
    /// location.
    indirect case optional(pattern: PatternLocation)
}
