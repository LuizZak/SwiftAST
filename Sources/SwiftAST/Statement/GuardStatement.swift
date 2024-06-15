public class GuardStatement: Statement, StatementKindType {
    public var statementKind: StatementKind {
        .guard(self)
    }

    /// Gets the main conditional clauses of this guard statement.
    public var conditionalClauses: ConditionalClauses {
        didSet { oldValue.parent = nil; conditionalClauses.parent = self }
    }
    public var elseBody: CompoundStatement {
        didSet { oldValue.parent = nil; elseBody.parent = self }
    }

    /// Convenience for `conditionalClauses.clauses[0]`.
    internal var firstClause: ConditionalClauseElement {
        get { conditionalClauses.clauses[0] }
        set { conditionalClauses.clauses[0] = newValue }
    }

    /// Gets the first conditional clause expression in this guard statement.
    ///
    /// Convenience for `conditionalClauses.clauses[0].expression`.
    @available(*, deprecated, message: "Use conditionalClauses instead")
    public var exp: Expression {
        get { firstClause.expression }
        set { firstClause.expression = newValue }
    }

    /// If non-nil, the expression of this guard statement must be resolved to a
    /// pattern match over a given pattern.
    ///
    /// This is used to create guard-let statements.
    ///
    /// Convenience for `conditionalClauses.clauses[0].pattern`.
    @available(*, deprecated, message: "Use conditionalClauses instead")
    public var pattern: Pattern? {
        get { firstClause.pattern }
        set { firstClause.pattern = newValue }
    }

    /// Returns whether this `GuardExpression` represents a guard-let statement.
    @available(*, deprecated, renamed: "conditionalClauses.hasBindings", message: "Use conditionalClauses.hasBindings instead")
    public var isGuardLet: Bool {
        pattern != nil
    }

    public override var children: [SyntaxNode] {
        [conditionalClauses, elseBody]
    }

    public override var isLabelableStatementType: Bool {
        return false
    }

    public convenience init(
        exp: Expression,
        elseBody: CompoundStatement,
        pattern: Pattern?
    ) {
        self.init(
            clauses: [.init(pattern: pattern, expression: exp)],
            elseBody: elseBody
        )
    }

    public init(clauses: ConditionalClauses, elseBody: CompoundStatement) {
        self.conditionalClauses = clauses
        self.elseBody = elseBody

        super.init()

        conditionalClauses.parent = self
        elseBody.parent = self
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        conditionalClauses = try container.decode(ConditionalClauses.self, forKey: .conditionalClauses)
        elseBody = try container.decodeStatement(CompoundStatement.self, forKey: .elseBody)

        try super.init(from: container.superDecoder())

        conditionalClauses.parent = self
        elseBody.parent = self
    }

    @inlinable
    public override func copy() -> GuardStatement {
        let copy =
            GuardStatement(
                clauses: conditionalClauses.copy(),
                elseBody: elseBody.copy()
            )
            .copyMetadata(from: self)

        return copy
    }

    @inlinable
    public override func accept<V: StatementVisitor>(_ visitor: V) -> V.StmtResult {
        visitor.visitGuard(self)
    }

    @inlinable
    public override func accept<V: StatementStatefulVisitor>(_ visitor: V, state: V.State) -> V.StmtResult {
        visitor.visitGuard(self, state: state)
    }

    public override func isEqual(to other: Statement) -> Bool {
        switch other {
        case let rhs as GuardStatement:
            return conditionalClauses.isEqual(to: rhs.conditionalClauses) && elseBody == rhs.elseBody && elseBody == rhs.elseBody
        default:
            return false
        }
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(conditionalClauses, forKey: .conditionalClauses)
        try container.encodeStatement(elseBody, forKey: .elseBody)

        try super.encode(to: container.superEncoder())
    }

    private enum CodingKeys: String, CodingKey {
        case conditionalClauses
        case elseBody
    }
}
public extension Statement {
    /// Returns `self as? GuardStatement`.
    @inlinable
    var asGuard: GuardStatement? {
        cast()
    }

    /// Returns `true` if this `Statement` is an instance of `GuardStatement`
    /// class.
    @inlinable
    var isGuard: Bool {
        asGuard != nil
    }

    /// Creates a `GuardStatement` instance using the given condition expression
    /// and compound statement as its body, with a given else block.
    static func `guard`(
        _ exp: Expression,
        else elseBody: CompoundStatement
    ) -> GuardStatement {

        GuardStatement(exp: exp, elseBody: elseBody, pattern: nil)
    }

    /// Creates a `GuardStatement` instance for a guard-let binding using the
    /// given pattern wrapped in a valueBindingPattern, condition expression,
    /// with a given else block.
    static func guardLet(
        _ pattern: Pattern,
        _ exp: Expression,
        else elseBody: CompoundStatement
    ) -> GuardStatement {

        GuardStatement(
            exp: exp,
            elseBody: elseBody,
            pattern: .valueBindingPattern(constant: true, pattern)
        )
    }

    /// Creates a `GuardStatement` instance using the given condition clauses
    /// and compound statement as its body, with a given else block.
    static func `guard`(
        clauses: ConditionalClauses,
        else elseBody: CompoundStatement
    ) -> GuardStatement {

        GuardStatement(clauses: clauses, elseBody: elseBody)
    }
}
