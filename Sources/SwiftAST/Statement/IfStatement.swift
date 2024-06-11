public class IfStatement: Statement, StatementKindType {
    public var statementKind: StatementKind {
        .if(self)
    }

    /// Gets the main conditional clauses of this if statement.
    public var conditionalClauses: ConditionalClauses {
        didSet { oldValue.parent = nil; conditionalClauses.parent = self }
    }

    /// Convenience for `conditionalClauses.clauses[0]`.
    internal var firstClause: ConditionalClauseElement {
        get { conditionalClauses.clauses[0] }
        set { conditionalClauses.clauses[0] = newValue }
    }

    /// Gets the first conditional clause expression in this if statement.
    ///
    /// Convenience for `conditionalClauses.clauses[0].expression`.
    public var exp: Expression {
        get {
            firstClause.expression
        }
        set {
            firstClause = .init(
                pattern: firstClause.pattern,
                expression: newValue
            )
        }
    }
    public var body: CompoundStatement {
        didSet { oldValue.parent = nil; body.parent = self }
    }
    public var elseBody: CompoundStatement? {
        didSet { oldValue?.parent = nil; elseBody?.parent = self }
    }

    /// If non-nil, the expression of this if statement must be resolved to a
    /// pattern match over a given pattern.
    ///
    /// This is used to create if-let statements.
    ///
    /// Convenience for `conditionalClauses.clauses[0].pattern`.
    public var pattern: Pattern? {
        get {
            firstClause.pattern
        }
        set {
            firstClause = .init(
                pattern: newValue,
                expression: firstClause.expression
            )
        }
    }

    /// Returns whether this `IfExpression` represents an if-let statement.
    public var isIfLet: Bool {
        pattern != nil
    }

    public override var children: [SyntaxNode] {
        var result: [SyntaxNode] = []

        conditionalClauses.collect(expressions: &result)

        result.append(body)

        if let elseBody = elseBody {
            result.append(elseBody)
        }

        return result
    }

    public override var isLabelableStatementType: Bool {
        return true
    }

    public convenience init(
        exp: Expression,
        body: CompoundStatement,
        elseBody: CompoundStatement?,
        pattern: Pattern?
    ) {
        self.init(
            clauses: .init(pattern: pattern, expression: exp),
            body: body,
            elseBody: elseBody
        )
    }

    public init(
        clauses: ConditionalClauses,
        body: CompoundStatement,
        elseBody: CompoundStatement?
    ) {

        self.conditionalClauses = clauses
        self.body = body
        self.elseBody = elseBody

        super.init()

        conditionalClauses.parent = self
        body.parent = self
        elseBody?.parent = self
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        conditionalClauses = try container.decode(ConditionalClauses.self, forKey: .conditionalClauses)
        body = try container.decodeStatement(CompoundStatement.self, forKey: .body)
        elseBody = try container.decodeStatementIfPresent(CompoundStatement.self, forKey: .elseBody)

        try super.init(from: container.superDecoder())

        exp.parent = self
        body.parent = self
        elseBody?.parent = self
        pattern?.setParent(self)
    }

    @inlinable
    public override func copy() -> IfStatement {
        let copy =
            IfStatement(
                exp: exp.copy(),
                body: body.copy(),
                elseBody: elseBody?.copy(),
                pattern: pattern?.copy()
            )
            .copyMetadata(from: self)

        copy.pattern = pattern?.copy()

        return copy
    }

    @inlinable
    public override func accept<V: StatementVisitor>(_ visitor: V) -> V.StmtResult {
        visitor.visitIf(self)
    }

    @inlinable
    public override func accept<V: StatementStatefulVisitor>(_ visitor: V, state: V.State) -> V.StmtResult {
        visitor.visitIf(self, state: state)
    }

    public override func isEqual(to other: Statement) -> Bool {
        switch other {
        case let rhs as IfStatement:
            return conditionalClauses.isEqual(to: rhs.conditionalClauses) && body == rhs.body && elseBody == rhs.elseBody
        default:
            return false
        }
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(conditionalClauses, forKey: .conditionalClauses)
        try container.encodeStatement(body, forKey: .body)
        try container.encodeStatementIfPresent(elseBody, forKey: .elseBody)

        try super.encode(to: container.superEncoder())
    }

    private enum CodingKeys: String, CodingKey {
        case conditionalClauses
        case body
        case elseBody
    }
}
public extension Statement {
    /// Returns `self as? IfStatement`.
    @inlinable
    var asIf: IfStatement? {
        cast()
    }

    /// Returns `true` if this `Statement` is an instance of `IfStatement`
    /// class.
    @inlinable
    var isIf: Bool {
        asIf != nil
    }

    /// Creates a `IfStatement` instance using the given condition expression
    /// and compound statement as its body, optionally specifying an else block.
    static func `if`(
        _ exp: Expression,
        body: CompoundStatement,
        else elseBody: CompoundStatement? = nil
    ) -> IfStatement {

        IfStatement(exp: exp, body: body, elseBody: elseBody, pattern: nil)
    }

    /// Creates a `IfStatement` instance for an if-let binding using the given
    /// pattern and condition expression and compound statement as its body,
    /// optionally specifying an else block.
    static func ifLet(
        _ pattern: Pattern,
        _ exp: Expression,
        body: CompoundStatement,
        else elseBody: CompoundStatement? = nil
    ) -> IfStatement {

        IfStatement(exp: exp, body: body, elseBody: elseBody, pattern: pattern)
    }

    /// Creates a `IfStatement` instance using the given conditional clauses
    /// and compound statement as its body, optionally specifying an else block.
    static func `if`(
        clauses: ConditionalClauses,
        body: CompoundStatement,
        else elseBody: CompoundStatement? = nil
    ) -> IfStatement {

        IfStatement(clauses: clauses, body: body, elseBody: elseBody)
    }
}
