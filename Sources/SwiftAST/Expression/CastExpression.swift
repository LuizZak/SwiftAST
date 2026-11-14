/// `<exp> as[?/!] <type>`
public class CastExpression: Expression, ExpressionKindType {
    public var expressionKind: ExpressionKind {
        .cast(self)
    }

    public var exp: Expression {
        didSet { oldValue.parent = nil; exp.parent = self }
    }
    public var type: SwiftType
    public var kind: Kind

    public override var subExpressions: [Expression] {
        [exp]
    }

    public override var description: String {
        switch kind {
        case .normal:
            return "\(exp) as \(type)"
        case .optional:
            return "\(exp) as? \(type)"
        case .forced:
            return "\(exp) as! \(type)"
        }
    }

    public override var requiresParens: Bool {
        true
    }

    public init(exp: Expression, type: SwiftType, kind: Kind) {
        self.exp = exp
        self.type = type
        self.kind = kind

        super.init()

        exp.parent = self
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        exp = try container.decodeExpression(forKey: .exp)
        type = try container.decode(SwiftType.self, forKey: .type)
        kind = try container.decode(Kind.self, forKey: .kind)

        try super.init(from: container.superDecoder())

        exp.parent = self
    }

    @inlinable
    public override func copy() -> CastExpression {
        CastExpression(exp: exp.copy(), type: type, kind: kind).copyTypeAndMetadata(from: self)
    }

    @inlinable
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        visitor.visitCast(self)
    }

    public override func isEqual(to other: Expression) -> Bool {
        switch other {
        case let rhs as CastExpression:
            return self == rhs
        default:
            return false
        }
    }

    public override func hash(into hasher: inout Hasher) {
        super.hash(into: &hasher)

        hasher.combine(exp)
        hasher.combine(type)
        hasher.combine(kind)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeExpression(exp, forKey: .exp)
        try container.encode(type, forKey: .type)
        try container.encode(kind, forKey: .kind)

        try super.encode(to: container.superEncoder())
    }

    public static func == (lhs: CastExpression, rhs: CastExpression) -> Bool {
        if lhs === rhs {
            return true
        }

        return lhs.exp == rhs.exp &&
            lhs.type == rhs.type &&
            lhs.kind == rhs.kind
    }

    private enum CodingKeys: String, CodingKey {
        case exp
        case type
        case kind
    }

    public enum Kind: Codable, Sendable {
        case normal
        case optional
        case forced
    }
}
public extension Expression {
    @inlinable
    var asCast: CastExpression? {
        cast()
    }

    @inlinable
    var isCast: Bool {
        asCast != nil
    }

    /// Creates a type-cast expression with this expression
    func casted(to type: SwiftType, kind: CastExpression.Kind = .optional) -> CastExpression {
        .cast(expressionToBuild, type: type, kind: kind)
    }

    static func cast(_ exp: Expression, type: SwiftType, kind: CastExpression.Kind = .optional) -> CastExpression {
        CastExpression(exp: exp, type: type, kind: kind)
    }
}

extension CastExpression {

    public func copyTypeAndMetadata(from other: CastExpression) -> Self {
        _ = (self as Expression).copyTypeAndMetadata(from: other)
        self.kind = other.kind

        return self
    }

}
