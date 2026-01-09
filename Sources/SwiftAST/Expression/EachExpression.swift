/// A swift `each` expression.
///
/// `each <exp>`
public class EachExpression: Expression, ExpressionKindType {
    public var expressionKind: ExpressionKind {
        .eachExpression(self)
    }

    public var exp: Expression {
        didSet { oldValue.parent = nil; exp.parent = self; }
    }

    public override var subExpressions: [Expression] {
        [exp]
    }

    public override var isLiteralExpression: Bool {
        false
    }

    public override var description: String {
        "each \(exp)"
    }

    public init(exp: Expression) {
        self.exp = exp

        super.init()

        exp.parent = self
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        exp = try container.decodeExpression(Expression.self, forKey: .exp)

        try super.init(from: container.superDecoder())

        exp.parent = self
    }

    @inlinable
    public override func copy() -> EachExpression {
        EachExpression(exp: exp.copy()).copyTypeAndMetadata(from: self)
    }

    @inlinable
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        visitor.visitEach(self)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeExpression(exp, forKey: .exp)

        try super.encode(to: container.superEncoder())
    }

    public override func isEqual(to other: Expression) -> Bool {
        switch other {
        case let rhs as EachExpression:
            return self == rhs
        default:
            return false
        }
    }

    public override func hash(into hasher: inout Hasher) {
        super.hash(into: &hasher)

        hasher.combine(exp)
    }

    public static func == (lhs: EachExpression, rhs: EachExpression) -> Bool {
        if lhs === rhs {
            return true
        }

        return lhs.exp == rhs.exp
    }

    private enum CodingKeys: String, CodingKey {
        case exp
    }
}
public extension Expression {
    @inlinable
    var asEach: EachExpression? {
        cast()
    }

    @inlinable
    var isEach: Bool {
        asEach != nil
    }

    static func `each`(_ exp: Expression) -> EachExpression {
        EachExpression(exp: exp)
    }
}
