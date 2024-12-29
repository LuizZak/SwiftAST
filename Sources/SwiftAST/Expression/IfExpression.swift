/// `if <clauses> { <body> } [else [if <clauses>] { <body> }]`
public class IfExpression: Expression, ExpressionKindType {
    public var expressionKind: ExpressionKind {
        .ifExpression(self)
    }

    /// Gets the main conditional clauses of this if statement.
    public var conditionalClauses: ConditionalClauses {
        didSet { oldValue.parent = nil; conditionalClauses.parent = self }
    }
    public var body: CompoundStatement {
        didSet { oldValue.parent = nil; body.parent = self }
    }
    public var elseBody: ElseBody? {
        didSet { oldValue?.setParent(nil); elseBody?.setParent(self) }
    }

    /// Convenience for `conditionalClauses.clauses[0]`.
    internal var firstClause: ConditionalClauseElement {
        get { conditionalClauses.clauses[0] }
        set { conditionalClauses.clauses[0] = newValue }
    }

    /// Gets the first conditional clause expression in this if statement.
    ///
    /// Convenience for `conditionalClauses.clauses[0].expression`.
    @available(*, deprecated, message: "Use conditionalClauses instead")
    public var exp: Expression {
        get { firstClause.expression }
        set { firstClause.expression = newValue }
    }

    /// If non-nil, the expression of this if statement must be resolved to a
    /// pattern match over a given pattern.
    ///
    /// This is used to create if-let statements.
    ///
    /// Convenience for `conditionalClauses.clauses[0].pattern`.
    @available(*, deprecated, message: "Use conditionalClauses instead")
    public var pattern: Pattern? {
        get { firstClause.pattern }
        set { firstClause.pattern = newValue }
    }

    /// Returns whether this `IfExpression` represents an if-let statement.
    @available(*, deprecated, renamed: "conditionalClauses.hasBindings", message: "Use conditionalClauses.hasBindings instead")
    public var isIfLet: Bool {
        conditionalClauses.clauses.contains(where: \.hasBindings)
    }

    public override var children: [SyntaxNode] {
        var result: [SyntaxNode] = [
            conditionalClauses,
            body
        ]

        if let elseBody = elseBody?.statement {
            result.append(elseBody)
        }

        return result
    }

    public override var isLabelableExpressionType: Bool {
        return true
    }

    public convenience init(
        exp: Expression,
        body: CompoundStatement,
        else elseBody: CompoundStatement?,
        pattern: Pattern?
    ) {
        self.init(
            clauses: .init(pattern: pattern, expression: exp),
            body: body,
            elseBody: elseBody.map(ElseBody.else)
        )
    }

    public convenience init(
        exp: Expression,
        body: CompoundStatement,
        elseBody: ElseBody?,
        pattern: Pattern? = nil
    ) {

        self.init(
            clauses: .init(pattern: pattern, expression: exp),
            body: body,
            elseBody: elseBody
        )
    }

    public convenience init(
        clauses: ConditionalClauses,
        body: CompoundStatement,
        else elseBody: CompoundStatement?
    ) {

        self.init(
            clauses: clauses,
            body: body,
            elseBody: elseBody.map(ElseBody.else)
        )
    }

    public init(
        clauses: ConditionalClauses,
        body: CompoundStatement,
        elseBody: ElseBody?
    ) {

        self.conditionalClauses = clauses
        self.body = body
        self.elseBody = elseBody

        super.init()

        conditionalClauses.parent = self
        body.parent = self
        elseBody?.setParent(self)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        conditionalClauses = try container.decode(ConditionalClauses.self, forKey: .conditionalClauses)
        body = try container.decodeStatement(CompoundStatement.self, forKey: .body)
        elseBody = try container.decodeIfPresent(ElseBody.self, forKey: .elseBody)

        try super.init(from: container.superDecoder())

        conditionalClauses.parent = self
        body.parent = self
        elseBody?.setParent(self)
    }

    @inlinable
    public override func copy() -> IfExpression {
        let copy =
            IfExpression(
                clauses: conditionalClauses.copy(),
                body: body.copy(),
                elseBody: elseBody?.copy()
            )

        return copy
    }

    @inlinable
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        visitor.visitIf(self)
    }

    public override func isEqual(to other: Expression) -> Bool {
        switch other {
        case let rhs as IfExpression:
            return conditionalClauses.isEqual(to: rhs.conditionalClauses) && body == rhs.body && elseBody == rhs.elseBody
        default:
            return false
        }
    }

    public override func hash(into hasher: inout Hasher) {
        super.hash(into: &hasher)

        hasher.combine(conditionalClauses)
        hasher.combine(body)
        hasher.combine(elseBody)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(conditionalClauses, forKey: .conditionalClauses)
        try container.encodeStatement(body, forKey: .body)
        try container.encodeIfPresent(elseBody, forKey: .elseBody)

        try super.encode(to: container.superEncoder())
    }

    private enum CodingKeys: String, CodingKey {
        case conditionalClauses
        case body
        case elseBody
    }
}
public extension Expression {
    /// Returns `self as? IfExpression`.
    @inlinable
    var asIf: IfExpression? {
        cast()
    }

    /// Returns `true` if this `Statement` is an instance of `IfExpression`
    /// class.
    @inlinable
    var isIf: Bool {
        asIf != nil
    }

    /// Creates a `IfExpression` instance using the given condition expression
    /// and compound statement as its body, optionally specifying an else block.
    static func `if`(
        _ exp: Expression,
        body: CompoundStatement,
        else elseBody: CompoundStatement? = nil
    ) -> IfExpression {

        IfExpression(exp: exp, body: body, else: elseBody, pattern: nil)
    }

    /// Creates a `IfExpression` instance for an if-let binding using the given
    /// pattern wrapped in a valueBindingPattern, condition expression, and
    /// compound statement as its body, optionally specifying an else block.
    static func ifLet(
        _ pattern: Pattern,
        _ exp: Expression,
        body: CompoundStatement,
        else elseBody: CompoundStatement? = nil
    ) -> IfExpression {

        IfExpression(
            exp: exp,
            body: body,
            else: elseBody,
            pattern: .valueBindingPattern(constant: true, pattern)
        )
    }

    /// Creates a `IfExpression` instance using the given conditional clauses
    /// and compound statement as its body, optionally specifying an else block.
    static func `if`(
        clauses: ConditionalClauses,
        body: CompoundStatement,
        else elseBody: CompoundStatement? = nil
    ) -> IfExpression {

        IfExpression(clauses: clauses, body: body, else: elseBody)
    }

    /// Creates a `IfExpression` instance using the given condition expression
    /// and compound statement as its body, optionally specifying an else block.
    static func `if`(
        _ exp: Expression,
        body: CompoundStatement,
        elseIf stmt: IfExpression
    ) -> IfExpression {

        IfExpression(exp: exp, body: body, elseBody: .elseIf(stmt))
    }

    /// Creates a `IfExpression` instance using the given conditional clauses
    /// and compound statement as its body, with a given if statement as an
    /// else-if block.
    static func `if`(
        clauses: ConditionalClauses,
        body: CompoundStatement,
        elseIf stmt: IfExpression
    ) -> IfExpression {

        IfExpression(clauses: clauses, body: body, elseBody: .elseIf(stmt))
    }

    /// Creates a `IfExpression` instance using the given conditional clauses
    /// and compound statement as its body, with a given else block.
    static func `if`(
        clauses: ConditionalClauses,
        body: CompoundStatement,
        elseBody: IfExpression.ElseBody
    ) -> IfExpression {

        IfExpression(clauses: clauses, body: body, elseBody: elseBody)
    }
}
public extension Statement {
    /// Returns an inner expression of `IfExpression` if this statement is an
    /// `ExpressionsStatement` containing exactly one instance of `IfExpression`.
    @inlinable
    var asIf: IfExpression? {
        guard let expressions: ExpressionsStatement = self.asExpressions else {
            return nil
        }
        guard expressions.expressions.count == 1 else {
            return nil
        }
        return expressions.expressions[0].asIf
    }

    /// Returns `true` if this `Statement` is an instance of `IfExpression`
    /// class.
    @inlinable
    var isIf: Bool {
        asIf != nil
    }

    /// Creates a `IfExpression` instance using the given condition expression
    /// and compound statement as its body, optionally specifying an else block.
    static func `if`(
        _ exp: Expression,
        body: CompoundStatement,
        else elseBody: CompoundStatement? = nil
    ) -> ExpressionsStatement {

        let exp = IfExpression(exp: exp, body: body, else: elseBody, pattern: nil)

        return .expression(exp)
    }

    /// Creates a `IfExpression` instance for an if-let binding using the given
    /// pattern wrapped in a valueBindingPattern, condition expression, and
    /// compound statement as its body, optionally specifying an else block.
    static func ifLet(
        _ pattern: Pattern,
        _ exp: Expression,
        body: CompoundStatement,
        else elseBody: CompoundStatement? = nil
    ) -> ExpressionsStatement {

        let exp = IfExpression(
            exp: exp,
            body: body,
            else: elseBody,
            pattern: .valueBindingPattern(constant: true, pattern)
        )

        return .expression(exp)
    }

    /// Creates a `IfExpression` instance using the given conditional clauses
    /// and compound statement as its body, optionally specifying an else block.
    static func `if`(
        clauses: ConditionalClauses,
        body: CompoundStatement,
        else elseBody: CompoundStatement? = nil
    ) -> ExpressionsStatement {

        let exp = IfExpression(clauses: clauses, body: body, else: elseBody)

        return .expression(exp)
    }

    /// Creates a `IfExpression` instance using the given condition expression
    /// and compound statement as its body, optionally specifying an else block.
    static func `if`(
        _ exp: Expression,
        body: CompoundStatement,
        elseIf stmt: IfExpression
    ) -> ExpressionsStatement {

        let exp = IfExpression(exp: exp, body: body, elseBody: .elseIf(stmt))

        return .expression(exp)
    }

    /// Creates a `IfExpression` instance using the given conditional clauses
    /// and compound statement as its body, with a given if statement as an
    /// else-if block.
    static func `if`(
        clauses: ConditionalClauses,
        body: CompoundStatement,
        elseIf stmt: IfExpression
    ) -> ExpressionsStatement {

        let exp = IfExpression(clauses: clauses, body: body, elseBody: .elseIf(stmt))

        return .expression(exp)
    }

    /// Creates a `IfExpression` instance using the given conditional clauses
    /// and compound statement as its body, with a given else block.
    static func `if`(
        clauses: ConditionalClauses,
        body: CompoundStatement,
        elseBody: IfExpression.ElseBody
    ) -> ExpressionsStatement {

        let exp = IfExpression(clauses: clauses, body: body, elseBody: elseBody)

        return .expression(exp)
    }
}

// MARK: - Else/ElseIf Structure
public extension IfExpression {

    /// Describes the else statement of an `if` statement.
    enum ElseBody: Codable, Equatable, Hashable {
        /// An else statement.
        case `else`(CompoundStatement)

        /// A nested `if` statement.
        case elseIf(IfExpression)

        public var statement: Statement? {
            switch self {
            case .else(let stmt): return stmt
            case .elseIf: return nil
            }
        }

        public var ifExpression: IfExpression? {
            switch self {
            case .elseIf(let ifExpression): return ifExpression
            case .else: return nil
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            let discriminator = try container.decode(String.self, forKey: .discriminator)

            switch discriminator {
            case "else":
                self = try .else(
                    container.decodeStatement(forKey: .payload)
                )

            case "elseIf":
                self = try .elseIf(
                    container.decodeExpression(forKey: .payload)
                )

            default:
                throw DecodingError.dataCorruptedError(
                    forKey: CodingKeys.discriminator,
                    in: container,
                    debugDescription: "Invalid discriminator tag \(discriminator)"
                )
            }
        }

        @inlinable
        public func copy() -> Self {
            switch self {
            case .else(let stmts):
                return .else(stmts.copy())

            case .elseIf(let stmt):
                return .elseIf(stmt.copy())
            }
        }

        internal func setParent(_ node: SyntaxNode?) {
            switch self {
            case .else(let stmts):
                stmts.parent = node

            case .elseIf(let stmt):
                stmt.parent = node
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .else(let stmts):
                try container.encode("else", forKey: .discriminator)
                try container.encodeStatement(stmts, forKey: .payload)

            case .elseIf(let stmt):
                try container.encode("elseIf", forKey: .discriminator)
                try container.encodeExpression(stmt, forKey: .payload)
            }
        }

        public enum CodingKeys: String, CodingKey {
            case discriminator
            case payload
        }
    }
}
