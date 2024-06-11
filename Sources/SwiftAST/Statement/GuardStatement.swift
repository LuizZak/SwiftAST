public class GuardStatement: Statement, StatementKindType {
    public var statementKind: StatementKind {
        .guard(self)
    }

    public var exp: Expression {
        didSet { oldValue.parent = nil; exp.parent = self }
    }
    public var elseBody: CompoundStatement {
        didSet { oldValue.parent = nil; elseBody.parent = self }
    }

    /// If non-nil, the expression of this guard statement must be resolved to a
    /// pattern match over a given pattern.
    ///
    /// This is used to create guard-let statements.
    public var pattern: Pattern? {
        didSet {
            oldValue?.setParent(nil)
            pattern?.setParent(self)
        }
    }

    /// Returns whether this `GuardExpression` represents a guard-let statement.
    public var isGuardLet: Bool {
        pattern != nil
    }

    public override var children: [SyntaxNode] {
        var result: [SyntaxNode] = []

        if let pattern = pattern {
            pattern.collect(expressions: &result)
        }

        result.append(exp)
        result.append(elseBody)

        return result
    }

    public override var isLabelableStatementType: Bool {
        return false
    }

    public init(exp: Expression, elseBody: CompoundStatement, pattern: Pattern?) {
        self.exp = exp
        self.elseBody = elseBody
        self.pattern = pattern

        super.init()

        exp.parent = self
        elseBody.parent = self
        pattern?.setParent(self)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        exp = try container.decodeExpression(forKey: .exp)
        elseBody = try container.decodeStatement(CompoundStatement.self, forKey: .elseBody)
        pattern = try container.decodeIfPresent(Pattern.self, forKey: .pattern)

        try super.init(from: container.superDecoder())

        exp.parent = self
        elseBody.parent = self
        pattern?.setParent(self)
    }

    @inlinable
    public override func copy() -> GuardStatement {
        let copy =
            GuardStatement(
                exp: exp.copy(),
                elseBody: elseBody.copy(),
                pattern: pattern?.copy()
            )
            .copyMetadata(from: self)

        copy.pattern = pattern?.copy()

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
            return exp == rhs.exp && pattern == rhs.pattern && elseBody == rhs.elseBody && elseBody == rhs.elseBody
        default:
            return false
        }
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(pattern, forKey: .pattern)
        try container.encodeExpression(exp, forKey: .exp)
        try container.encodeStatement(elseBody, forKey: .elseBody)

        try super.encode(to: container.superEncoder())
    }

    private enum CodingKeys: String, CodingKey {
        case pattern
        case exp
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

    /// Creates a `GuardStatement` instance for an guard-let binding using the
    /// given pattern and condition expression and compound statement as its
    /// body, with a given else block.
    static func guardLet(
        _ pattern: Pattern,
        _ exp: Expression,
        else elseBody: CompoundStatement
    ) -> GuardStatement {

        GuardStatement(exp: exp, elseBody: elseBody, pattern: pattern)
    }
}
