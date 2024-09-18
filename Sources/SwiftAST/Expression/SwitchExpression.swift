public class SwitchExpression: Expression, ExpressionKindType {
    /// Cache of children expression and statements stored into each case pattern
    private var _childrenNodes: [SyntaxNode] = []

    public var expressionKind: ExpressionKind {
        .switch(self)
    }

    public var exp: Expression {
        didSet {
            oldValue.parent = nil
            exp.parent = self
        }
    }
    public var cases: [SwitchCase] {
        didSet {
            oldValue.forEach { $0.parent = nil }
            cases.forEach { $0.parent = self }
        }
    }
    public var defaultCase: SwitchDefaultCase? {
        didSet {
            oldValue?.parent = nil
            defaultCase?.parent = self
        }
    }

    /// If this switch expression is contained within a labeled `ExpressionsStatement`,
    /// returns the label associated with that statement.
    public var label: String? {
        guard let parent = parent as? ExpressionsStatement else {
            return nil
        }
        guard parent.expressions.count == 1 else {
            return nil
        }

        return parent.label
    }

    public override var children: [SyntaxNode] {
        var result = [exp] + cases
        if let defaultCase = defaultCase {
            result.append(defaultCase)
        }

        return result
    }

    public override var isLabelableExpressionType: Bool {
        return true
    }

    public init(exp: Expression, cases: [SwitchCase], defaultCase: SwitchDefaultCase?) {
        self.exp = exp
        self.cases = cases
        self.defaultCase = defaultCase

        super.init()

        adjustParent()
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        exp = try container.decodeExpression(Expression.self, forKey: .exp)
        cases = try container.decode([SwitchCase].self, forKey: .cases)
        defaultCase = try container.decodeIfPresent(SwitchDefaultCase.self, forKey: .defaultCase)

        try super.init(from: container.superDecoder())

        adjustParent()
    }

    fileprivate func adjustParent() {
        exp.parent = self
        cases.forEach { $0.parent = self }
        defaultCase?.parent = self
    }

    @inlinable
    public override func copy() -> SwitchExpression {
        SwitchExpression(
            exp: exp.copy(),
            cases: cases.map { $0.copy() },
            defaultCase: defaultCase?.copy()
        )
    }

    @inlinable
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        visitor.visitSwitch(self)
    }

    public override func isEqual(to other: Expression) -> Bool {
        switch other {
        case let rhs as SwitchExpression:
            return exp == rhs.exp && cases == rhs.cases && defaultCase == rhs.defaultCase
        default:
            return false
        }
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeExpression(exp, forKey: .exp)
        try container.encode(cases, forKey: .cases)
        try container.encode(defaultCase, forKey: .defaultCase)

        try super.encode(to: container.superEncoder())
    }

    private enum CodingKeys: String, CodingKey {
        case exp
        case cases
        case defaultCase
    }
}
public extension Expression {
    /// Returns an inner expression of `SwitchExpression` if this statement is an
    /// `ExpressionsStatement` containing exactly one instance of `SwitchExpression`.
    @inlinable
    var asSwitch: SwitchExpression? {
        cast()
    }

    /// Returns `true` if this `Statement` is an instance of `SwitchExpression`
    /// class.
    @inlinable
    var isSwitch: Bool {
        asSwitch != nil
    }

    /// Creates a `SwitchExpression` instance using the given expression and list
    /// of cases, optionally specifying a default case as a list of statements.
    static func `switch`(
        _ exp: Expression,
        cases: [SwitchCase],
        defaultStatements defaultCase: [Statement]?
    ) -> SwitchExpression {

        SwitchExpression(
            exp: exp,
            cases: cases,
            defaultCase: defaultCase.map(SwitchDefaultCase.init)
        )
    }

    /// Creates a `SwitchExpression` instance using the given expression and list
    /// of cases, optionally specifying a default case as a list of statements.
    static func `switch`(
        _ exp: Expression,
        cases: [SwitchCase],
        default defaultCase: SwitchDefaultCase?
    ) -> SwitchExpression {

        SwitchExpression(
            exp: exp,
            cases: cases,
            defaultCase: defaultCase
        )
    }
}
public extension Statement {
    /// Returns an inner expression of `SwitchExpression` if this statement is an
    /// `ExpressionsStatement` containing exactly one instance of `SwitchExpression`.
    @inlinable
    var asSwitch: SwitchExpression? {
        guard let expressions: ExpressionsStatement = self.asExpressions else {
            return nil
        }
        guard expressions.expressions.count == 1 else {
            return nil
        }
        return expressions.expressions[0].asSwitch
    }

    /// Returns `true` if this `Statement` is an instance of `SwitchExpression`
    /// class.
    @inlinable
    var isSwitch: Bool {
        asSwitch != nil
    }

    /// Creates a `SwitchExpression` instance using the given expression and list
    /// of cases, optionally specifying a default case as a list of statements.
    static func `switch`(
        _ exp: Expression,
        cases: [SwitchCase],
        defaultStatements defaultCase: [Statement]?
    ) -> ExpressionsStatement {

        let exp = SwitchExpression(
            exp: exp,
            cases: cases,
            defaultCase: defaultCase.map(SwitchDefaultCase.init)
        )

        return .expression(exp)
    }

    /// Creates a `SwitchExpression` instance using the given expression and list
    /// of cases, optionally specifying a default case as a list of statements.
    static func `switch`(
        _ exp: Expression,
        cases: [SwitchCase],
        default defaultCase: SwitchDefaultCase?
    ) -> ExpressionsStatement {

        let exp = SwitchExpression(
            exp: exp,
            cases: cases,
            defaultCase: defaultCase
        )

        return .expression(exp)
    }
}

public class SwitchCase: SyntaxNode, Codable, Equatable {
    /// Case patterns for this switch case.
    public var casePatterns: [CasePattern] {
        didSet {
            oldValue.forEach { $0.setParent(nil) }
            casePatterns.forEach { $0.setParent(self) }
        }
    }

    /// Patterns for this switch case.
    ///
    /// Convenience for `casePatterns.map(\.pattern)`
    public var patterns: [Pattern] {
        casePatterns.map(\.pattern)
    }

    /// Statements for the switch case
    public var statements: [Statement] {
        body.statements
    }

    public var body: CompoundStatement {
        didSet {
            oldValue.parent = nil
            body.parent = self
        }
    }

    public override var children: [SyntaxNode] {
        casePatterns.flatMap(\.subExpressions) + [body]
    }

    public convenience init(
        patterns: [Pattern],
        statements: [Statement]
    ) {
        self.init(patterns: patterns, body: CompoundStatement(statements: statements))
    }

    public convenience init(patterns: [Pattern], body: CompoundStatement) {
        self.init(
            casePatterns: patterns.map {
                CasePattern(pattern: $0)
            },
            body: body
        )
    }

    public init(casePatterns: [CasePattern], body: CompoundStatement) {
        self.casePatterns = casePatterns
        self.body = body
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.casePatterns = try container.decode([CasePattern].self, forKey: .casePatterns)
        self.body = try container.decodeStatement(forKey: .body)
    }

    @inlinable
    public override func copy() -> SwitchCase {
        SwitchCase(
            casePatterns: casePatterns.map { $0.copy() },
            body: body.copy()
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(casePatterns, forKey: .casePatterns)
        try container.encodeStatement(body, forKey: .body)
    }

    public static func == (lhs: SwitchCase, rhs: SwitchCase) -> Bool {
        lhs === lhs || (lhs.casePatterns == rhs.casePatterns && lhs.body == rhs.body)
    }

    /// A switch-case's pattern entry.
    public struct CasePattern: Codable, Equatable {
        /// The pattern for the case.
        public let pattern: Pattern

        /// An optional `where` clause appended at the end of the case pattern.
        public let whereClause: Expression?

        /// Returns a list of sub-expressions contained within this case pattern.
        public var subExpressions: [Expression] {
            if let whereClause {
                return pattern.subExpressions + [whereClause]
            }

            return pattern.subExpressions
        }

        public init(pattern: Pattern, whereClause: Expression? = nil) {
            self.pattern = pattern
            self.whereClause = whereClause
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.pattern = try container.decode(Pattern.self, forKey: CodingKeys.pattern)
            self.whereClause = try container.decodeExpressionIfPresent(Expression.self, forKey: CodingKeys.whereClause)
        }

        /// Creates a deep copy of this case pattern.
        public func copy() -> Self {
            .init(pattern: pattern.copy(), whereClause: whereClause?.copy())
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(self.pattern, forKey: CodingKeys.pattern)
            try container.encodeExpressionIfPresent(self.whereClause, forKey: CodingKeys.whereClause)
        }

        internal func setParent(_ node: SyntaxNode?) {
            pattern.setParent(node)
            whereClause?.parent = node
        }

        internal func collect(expressions: inout [SyntaxNode]) {
            pattern.collect(expressions: &expressions)
            if let whereClause {
                expressions.append(whereClause)
            }
        }

        private enum CodingKeys: CodingKey {
            case pattern
            case whereClause
        }
    }

    private enum CodingKeys: String, CodingKey {
        case casePatterns
        case body
    }
}

public class SwitchDefaultCase: SyntaxNode, Codable, Equatable {
    /// Statements for the switch case
    public var statements: [Statement] {
        body.statements
    }

    public var body: CompoundStatement {
        didSet {
            oldValue.parent = nil
            body.parent = self
        }
    }

    public override var children: [SyntaxNode] {
        [body]
    }

    public convenience init(statements: [Statement]) {
        self.init(body: CompoundStatement(statements: statements))
    }

    public init(body: CompoundStatement) {
        self.body = body
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.body = try container.decodeStatement(forKey: .body)
    }

    @inlinable
    public override func copy() -> SwitchDefaultCase {
        .init(
            body: body.copy()
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeStatement(body, forKey: .body)
    }

    public static func == (lhs: SwitchDefaultCase, rhs: SwitchDefaultCase) -> Bool {
        lhs === lhs || (lhs.body == rhs.body)
    }

    private enum CodingKeys: String, CodingKey {
        case body
    }
}

extension SwitchCase.CasePattern: CustomStringConvertible {
    public var description: String {
        if let whereClause {
            return "\(pattern) where \(whereClause)"
        }

        return pattern.description
    }
}
