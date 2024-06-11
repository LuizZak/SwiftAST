/// Conditional clause of of a conditional statement.
public final class ConditionalClauses: SyntaxNode, Codable {
    /// The set of clauses for this conditional clause.
    ///
    /// A valid conditional clause always has at least one clause element, and
    /// this may be enforced during runtime by assertion failures.
    public var clauses: [ConditionalClauseElement] {
        willSet {
            clauses.forEach { $0.setParent(nil) }
        }
        didSet {
            clauses.forEach { $0.setParent(self) }
        }
    }

    public override var children: [SyntaxNode] {
        clauses.flatMap(\.subExpressions)
    }

    public init(clauses: [ConditionalClauseElement]) {
        assert(
            !clauses.isEmpty,
            "Attempted to create conditional clause with no elements"
        )

        self.clauses = clauses
    }

    /// Convenience initializer for generating conditional clauses with a single
    /// element.
    public convenience init(pattern: Pattern? = nil, expression: Expression) {
        self.init(clauses: [
            .init(pattern: pattern, expression: expression)
        ])
    }

    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.clauses = try container.decode([ConditionalClauseElement].self, forKey: CodingKeys.clauses)
    }

    @inlinable
    public override func copy() -> ConditionalClauses {
        ConditionalClauses(clauses: clauses.map { $0.copy() })
    }

    public func isEqual(to other: ConditionalClauses) -> Bool {
        guard self.clauses.count == other.clauses.count else {
            return false
        }

        return self.clauses.elementsEqual(other.clauses) {
            $0.isEqual(to: $1)
        }
    }

    internal func collect(expressions: inout [SyntaxNode]) {
        clauses.forEach { clause in
            clause.collect(expressions: &expressions)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.clauses, forKey: CodingKeys.clauses)
    }

    private enum CodingKeys: CodingKey {
        case clauses
    }
}

extension ConditionalClauses: ExpressibleByArrayLiteral {
    public convenience init(arrayLiteral elements: ConditionalClauseElement...) {
        self.init(clauses: elements)
    }
}

/// Conditional clause element for a conditional clause of a conditional statement.
public class ConditionalClauseElement: ExpressionComponent, Codable {
    /// An optional pattern that the expression is bound to.
    public let pattern: Pattern?

    /// The main expression of the clause.
    public let expression: Expression

    public var subExpressions: [Expression] {
        if let pattern {
            pattern.subExpressions + [expression]
        } else {
            [expression]
        }
    }

    public init(pattern: Pattern? = nil, expression: Expression) {
        self.pattern = pattern
        self.expression = expression
    }

    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.pattern = try container.decodeIfPresent(Pattern.self, forKey: .pattern)
        self.expression = try container.decodeExpression(forKey: .expression)
    }

    public func copy() -> ConditionalClauseElement {
        ConditionalClauseElement(
            pattern: pattern?.copy(),
            expression: expression.copy()
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(pattern, forKey: .pattern)
        try container.encodeExpression(expression, forKey: .expression)
    }

    internal func setParent(_ node: SyntaxNode?) {
        pattern?.setParent(node)
        expression.parent = node
    }

    internal func collect(expressions: inout [SyntaxNode]) {
        pattern?.collect(expressions: &expressions)
        expressions.append(expression)
    }

    public func isEqual(to other: ConditionalClauseElement) -> Bool {
        self.pattern == other.pattern && self.expression.isEqual(to: other.expression)
    }

    private enum CodingKeys: CodingKey {
        case pattern
        case expression
    }
}

extension ConditionalClauseElement: CustomStringConvertible {
    public var description: String {
        if let pattern {
            return "\(pattern) = \(expression)"
        } else {
            return expression.description
        }
    }
}
