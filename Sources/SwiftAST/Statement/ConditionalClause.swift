/// Conditional clause of of a conditional statement.
public final class ConditionalClauses: SyntaxNode, Equatable, Hashable, Codable {
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

    /// Returns `true` if any of the contained clauses within this conditional
    /// clause list contain a `Pattern.valueBindingPatterns` pattern.
    ///
    /// If no conditional clause contains any patterns, `false` is returned,
    /// instead.
    public var hasBindings: Bool {
        clauses.contains(where: \.hasBindings)
    }

    public init(clauses: [ConditionalClauseElement]) {
        assert(
            !clauses.isEmpty,
            "Attempted to create conditional clause with no elements"
        )

        self.clauses = clauses

        super.init()

        self.clauses.forEach { $0.parent = self }
    }

    /// Convenience initializer for generating conditional clauses with a single
    /// element.
    public convenience init(pattern: Pattern? = nil, expression: Expression) {
        self.init(clauses: [
            .init(pattern: pattern, expression: expression)
        ])
    }

    public required convenience init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init(clauses: try container.decode(
            [ConditionalClauseElement].self,
            forKey: CodingKeys.clauses
        ))
    }

    @inlinable
    public override func copy() -> ConditionalClauses {
        let copy = ConditionalClauses(
            clauses: clauses.map { $0.copy() }
        )
        copy.metadata = metadata

        return copy
    }

    public func isEqual(to other: ConditionalClauses) -> Bool {
        guard self.clauses.count == other.clauses.count else {
            return false
        }

        return self.clauses.elementsEqual(other.clauses) {
            $0.isEqual(to: $1)
        }
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(clauses)
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

    public static func == (lhs: ConditionalClauses, rhs: ConditionalClauses) -> Bool {
        lhs.isEqual(to: rhs)
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
public class ConditionalClauseElement: SyntaxNode, Equatable, Hashable, Codable {
    /// Whether this conditional clause element requires a 'case' keyword leading
    /// its pattern.
    public var isCaseClause: Bool

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

    /// Returns `true` if the pattern associated with this conditional clause
    /// contains `Pattern.valueBindingPatterns`.
    ///
    /// If this conditional clause contains no pattern, `false` is returned, instead.
    public var hasBindings: Bool {
        pattern?.hasBindings ?? false
    }

    public init(isCaseClause: Bool = false, pattern: Pattern? = nil, expression: Expression) {
        self.isCaseClause = isCaseClause
        self.pattern = pattern
        self.expression = expression

        super.init()

        self.pattern?.setParent(self)
        self.expression.parent = self
    }

    public required convenience init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init(
            isCaseClause: try container.decode(Bool.self, forKey: .isCaseClause),
            pattern: try container.decodeIfPresent(Pattern.self, forKey: .pattern),
            expression: try container.decodeExpression(forKey: .expression)
        )
    }

    public override func copy() -> ConditionalClauseElement {
        let copy = ConditionalClauseElement(
            isCaseClause: isCaseClause,
            pattern: pattern?.copy(),
            expression: expression.copy()
        )
        copy.metadata = metadata

        return copy
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(isCaseClause, forKey: .isCaseClause)
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
        self.isCaseClause == other.isCaseClause && self.pattern == other.pattern && self.expression.isEqual(to: other.expression)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(isCaseClause)
        hasher.combine(pattern)
        hasher.combine(expression)
    }

    public static func == (lhs: ConditionalClauseElement, rhs: ConditionalClauseElement) -> Bool {
        lhs.isEqual(to: rhs)
    }

    private enum CodingKeys: CodingKey {
        case isCaseClause
        case pattern
        case expression
    }
}

extension ConditionalClauseElement: CustomStringConvertible {
    public var description: String {
        if let pattern {
            let trail = "\(pattern) = \(expression)"
            if isCaseClause {
                return "case \(trail)"
            } else {
                return trail
            }
        } else {
            return expression.description
        }
    }
}
