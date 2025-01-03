/// `<identifier>` / `<identifier>(<args>)`
public class IdentifierExpression: Expression, ExpressibleByStringLiteral, ExpressionKindType {
    public var expressionKind: ExpressionKind {
        .identifier(self)
    }

    public var identifier: String
    public var argumentNames: [ArgumentName]?

    public override var description: String {
        if let argumentNames {
            return "\(identifier)(\(argumentNames.map(\.description).joined()))"
        }
        return identifier
    }

    public required init(stringLiteral value: String) {
        self.identifier = value

        super.init()
    }

    public convenience init(identifier: String) {
        self.init(identifier: identifier, argumentNames: nil)
    }

    public init(identifier: String, argumentNames: [ArgumentName]?) {
        self.identifier = identifier
        self.argumentNames = argumentNames

        super.init()
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        identifier = try container.decode(String.self, forKey: .identifier)
        argumentNames = try container.decodeIfPresent([ArgumentName].self, forKey: .argumentNames)

        try super.init(from: container.superDecoder())
    }

    @inlinable
    public override func copy() -> IdentifierExpression {
        IdentifierExpression(identifier: identifier).copyTypeAndMetadata(from: self)
    }

    @inlinable
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        visitor.visitIdentifier(self)
    }

    @inlinable
    public override func isEqual(to other: Expression) -> Bool {
        switch other {
        case let rhs as IdentifierExpression:
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
        try container.encodeIfPresent(argumentNames, forKey: .argumentNames)

        try super.encode(to: container.superEncoder())
    }

    public static func == (lhs: IdentifierExpression, rhs: IdentifierExpression) -> Bool {
        if lhs === rhs {
            return true
        }

        return lhs.identifier == rhs.identifier
    }

    public struct ArgumentName: Equatable, Hashable, Codable, CustomStringConvertible, ExpressibleByStringLiteral {
        public var identifier: String

        public var description: String {
            "\(identifier):"
        }

        public init(identifier: String) {
            self.identifier = identifier
        }

        public init(stringLiteral value: StringLiteralType) {
            self.identifier = value
        }
    }

    private enum CodingKeys: String, CodingKey {
        case identifier
        case argumentNames
    }
}
public extension Expression {
    @inlinable
    var asIdentifier: IdentifierExpression? {
        cast()
    }

    @inlinable
    var isIdentifier: Bool {
        asIdentifier != nil
    }

    static func identifier(_ ident: String) -> IdentifierExpression {
        IdentifierExpression(identifier: ident)
    }

    static func identifier(_ ident: String, argumentNames: [IdentifierExpression.ArgumentName]) -> IdentifierExpression {
        IdentifierExpression(identifier: ident, argumentNames: argumentNames)
    }
}
