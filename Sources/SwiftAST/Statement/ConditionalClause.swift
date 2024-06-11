/// Conditional clause of of a conditional statement.
public class ConditionalClause: ExpressionComponent, Codable {
    /// The set of clauses for this conditional clause.
    ///
    /// A valid conditional clause always has at least one clause element, and
    /// this may be enforced during runtime by assertion failures.
    public let clauses: [ConditionalClauseElement]

    public var subExpressions: [Expression] {
        clauses.flatMap(\.subExpressions)
    }

    public init(clauses: [ConditionalClauseElement]) {
        assert(
            !clauses.isEmpty,
            "Attempted to create conditional clause with no elements"
        )

        self.clauses = clauses
    }

    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.clauses = try container.decode([ConditionalClauseElement].self, forKey: CodingKeys.clauses)
    }

    public func copy() -> ConditionalClause {
        ConditionalClause(clauses: clauses.map { $0.copy() })
    }

    public func isEqual(to other: ConditionalClause) -> Bool {
        guard self.clauses.count == other.clauses.count else {
            return false
        }

        return self.clauses.elementsEqual(other.clauses) {
            $0.isEqual(to: $1)
        }
    }

    internal func setParent(_ node: SyntaxNode?) {
        clauses.forEach { clause in
            clause.setParent(node)
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

/// Conditional clause element for a conditional clause of a conditional statement.
public class ConditionalClauseElement: ExpressionComponent, Codable {
    /// The main expression of the clause.
    public let expression: Expression

    /// An optional pattern that the expression is bound to.
    public let pattern: Pattern?

    public var subExpressions: [Expression] {
        if let pattern {
            [expression] + pattern.subExpressions
        } else {
            [expression]
        }
    }

    public init(expression: Expression, pattern: Pattern? = nil) {
        self.expression = expression
        self.pattern = pattern
    }

    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.expression = try container.decodeExpression(forKey: .expression)
        self.pattern = try container.decodeIfPresent(Pattern.self, forKey: .pattern)
    }

    public func copy() -> ConditionalClauseElement {
        ConditionalClauseElement(
            expression: expression.copy(),
            pattern: pattern?.copy()
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeExpression(expression, forKey: .expression)
        try container.encodeIfPresent(self.pattern, forKey: .pattern)
    }

    internal func setParent(_ node: SyntaxNode?) {
        expression.parent = node
        pattern?.setParent(node)
    }

    internal func collect(expressions: inout [SyntaxNode]) {
        expressions.append(expression)
        pattern?.collect(expressions: &expressions)
    }

    public func isEqual(to other: ConditionalClauseElement) -> Bool {
        self.expression.isEqual(to: other.expression) && self.pattern == other.pattern
    }

    private enum CodingKeys: CodingKey {
        case expression
        case pattern
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
