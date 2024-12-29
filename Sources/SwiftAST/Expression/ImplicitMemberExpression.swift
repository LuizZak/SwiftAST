/// `.<identifier>`
public class ImplicitMemberExpression: Expression, ExpressibleByStringLiteral, ExpressionKindType {
    public var expressionKind: ExpressionKind {
        .implicitMember(self)
    }

    public var identifier: String

    public override var description: String {
        ".\(identifier)"
    }

    public required init(stringLiteral value: String) {
        self.identifier = value

        super.init()
    }

    public init(identifier: String) {
        self.identifier = identifier

        super.init()
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        identifier = try container.decode(String.self, forKey: .identifier)

        try super.init(from: container.superDecoder())
    }

    @inlinable
    public override func copy() -> ImplicitMemberExpression {
        ImplicitMemberExpression(identifier: identifier).copyTypeAndMetadata(from: self)
    }

    @inlinable
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        visitor.visitImplicitMember(self)
    }

    @inlinable
    public override func isEqual(to other: Expression) -> Bool {
        switch other {
        case let rhs as ImplicitMemberExpression:
            return self == rhs
        default:
            return false
        }
    }

    public override func hash(into hasher: inout Hasher) {
        super.hash(into: &hasher)

        hasher.combine(identifier)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(identifier, forKey: .identifier)

        try super.encode(to: container.superEncoder())
    }

    public static func == (lhs: ImplicitMemberExpression, rhs: ImplicitMemberExpression) -> Bool {
        if lhs === rhs {
            return true
        }

        return lhs.identifier == rhs.identifier
    }

    private enum CodingKeys: String, CodingKey {
        case identifier
    }
}
public extension Expression {
    @inlinable
    var asImplicitMemberExpression: ImplicitMemberExpression? {
        cast()
    }

    @inlinable
    var isImplicitMemberExpression: Bool {
        asImplicitMemberExpression != nil
    }

    static func implicitMember(_ ident: String) -> ImplicitMemberExpression {
        ImplicitMemberExpression(identifier: ident)
    }
}
