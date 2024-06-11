/// Conditional clause of of a conditional statement.
public final class ConditionalClauses: SyntaxNode, Codable {
    /// The set of clauses for this conditional clause.
    ///
    /// A valid conditional clause always has at least one clause element, and
    /// this may be enforced during runtime by assertion failures.
    public var clauses: [ConditionalClauseElement] {
        willSet { clauses.forEach { $0.parent = nil } }
        didSet { clauses.forEach { $0.parent = self } }
    }

    public override var children: [SyntaxNode] {
        clauses
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

        self.clauses = try container.decode(
            [ConditionalClauseElement].self,
            forKey: CodingKeys.clauses
        )
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

    @inlinable
    public func accept<V: StatementVisitor>(_ visitor: V) -> V.ConditionalClausesResult {
        visitor.visitConditionalClauses(self)
    }

    @inlinable
    public func accept<V: StatementStatefulVisitor>(_ visitor: V, state: V.State) -> V.ConditionalClausesResult {
        visitor.visitConditionalClauses(self, state: state)
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
public class ConditionalClauseElement: SyntaxNode, Codable {
    /// An optional pattern that the expression is bound to.
    public var pattern: Pattern? {
        didSet { oldValue?.setParent(nil); pattern?.setParent(self) }
    }

    /// The main expression of the clause.
    public var expression: Expression {
        didSet { oldValue.parent = nil; expression.parent = self }
    }

    public override var children: [SyntaxNode] {
        if let pattern {
            return pattern.subExpressions + [expression]
        } else {
            return [expression]
        }
    }

    public init(pattern: Pattern? = nil, expression: Expression) {
        self.pattern = pattern
        self.expression = expression

        super.init()
    }

    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.pattern = try container.decodeIfPresent(Pattern.self, forKey: .pattern)
        self.expression = try container.decodeExpression(forKey: .expression)
    }

    public override func copy() -> ConditionalClauseElement {
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

    @inlinable
    public func accept<V: StatementVisitor>(_ visitor: V) -> V.ConditionalClauseElementResult {
        visitor.visitConditionalClauseElement(self)
    }

    @inlinable
    public func accept<V: StatementStatefulVisitor>(_ visitor: V, state: V.State) -> V.ConditionalClauseElementResult {
        visitor.visitConditionalClauseElement(self, state: state)
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
