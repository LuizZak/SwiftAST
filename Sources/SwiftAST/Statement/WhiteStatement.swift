public class WhileStatement: Statement, StatementKindType {
    public var statementKind: StatementKind {
        .while(self)
    }

    /// Gets the main conditional clauses of this while statement.
    public var conditionalClauses: ConditionalClauses {
        didSet { oldValue.parent = nil; conditionalClauses.parent = self }
    }
    public var body: CompoundStatement {
        didSet {
            oldValue.parent = nil
            body.parent = self
        }
    }

    /// Convenience for `conditionalClauses.clauses[0]`.
    internal var firstClause: ConditionalClauseElement {
        get { conditionalClauses.clauses[0] }
        set { conditionalClauses.clauses[0] = newValue }
    }

    /// Gets the first conditional clause expression in this while statement.
    ///
    /// Convenience for `conditionalClauses.clauses[0].expression`.
    @available(*, deprecated, message: "Use conditionalClauses instead")
    public var exp: Expression {
        get { firstClause.expression }
        set { firstClause.expression = newValue }
    }

    public override var children: [SyntaxNode] {
        [conditionalClauses, body]
    }

    public override var isLabelableStatementType: Bool {
        return true
    }

    public convenience init(
        exp: Expression,
        body: CompoundStatement
    ) {
        self.init(
            clauses: [.init(expression: exp)],
            body: body
        )
    }

    public init(
        clauses: ConditionalClauses,
        body: CompoundStatement
    ) {
        self.conditionalClauses = clauses
        self.body = body

        super.init()

        self.conditionalClauses.parent = self
        body.parent = self
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        conditionalClauses = try container.decode(ConditionalClauses.self, forKey: .conditionalClauses)
        body = try container.decodeStatement(CompoundStatement.self, forKey: .body)

        try super.init(from: container.superDecoder())

        conditionalClauses.parent = self
        body.parent = self
    }

    @inlinable
    public override func copy() -> WhileStatement {
        WhileStatement(clauses: conditionalClauses.copy(), body: body.copy())
            .copyMetadata(from: self)
    }

    @inlinable
    public override func accept<V: StatementVisitor>(_ visitor: V) -> V.StmtResult {
        visitor.visitWhile(self)
    }

    @inlinable
    public override func accept<V: StatementStatefulVisitor>(_ visitor: V, state: V.State) -> V.StmtResult {
        visitor.visitWhile(self, state: state)
    }

    public override func isEqual(to other: Statement) -> Bool {
        switch other {
        case let rhs as WhileStatement:
            return conditionalClauses.isEqual(to: rhs.conditionalClauses) && body == rhs.body
        default:
            return false
        }
    }

    public override func hash(into hasher: inout Hasher) {
        super.hash(into: &hasher)

        hasher.combine(conditionalClauses)
        hasher.combine(body)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(conditionalClauses, forKey: .conditionalClauses)
        try container.encodeStatement(body, forKey: .body)

        try super.encode(to: container.superEncoder())
    }

    private enum CodingKeys: String, CodingKey {
        case conditionalClauses
        case body
    }
}
public extension Statement {
    /// Returns `self as? WhileStatement`.
    @inlinable
    var asWhile: WhileStatement? {
        cast()
    }

    /// Returns `true` if this `Statement` is an instance of `WhileStatement`
    /// class.
    @inlinable
    var isWhile: Bool {
        asWhile != nil
    }

    /// Creates a `WhileStatement` instance using the given condition expression
    /// and compound statement as its body.
    static func `while`(_ exp: Expression, body: CompoundStatement) -> WhileStatement {
        WhileStatement(exp: exp, body: body)
    }

    /// Creates a `WhileStatement` instance using the given condition clauses
    /// and compound statement as its body.
    static func `while`(clauses: ConditionalClauses, body: CompoundStatement) -> WhileStatement {
        WhileStatement(clauses: clauses, body: body)
    }
}
