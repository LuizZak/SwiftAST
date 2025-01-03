/// `{ (<parameters>) -> <return> in <body> }`
public class BlockLiteralExpression: Expression, ExpressionKindType {
    public var expressionKind: ExpressionKind {
        .blockLiteral(self)
    }

    public var signature: Signature?
    public var returnType: SwiftType? {
        signature?.returnType
    }
    public var parameters: [BlockParameter]? {
        signature?.parameters
    }

    public var body: CompoundStatement {
        didSet { oldValue.parent = nil; body.parent = self }
    }

    public override var children: [SyntaxNode] {
        [body]
    }

    public override var description: String {
        var buff = "{ "

        if let signature {
            buff += "\(signature) "
        }

        buff += "< body >"

        buff += " }"

        return buff
    }

    public override var requiresParens: Bool {
        true
    }

    public convenience init(parameters: [BlockParameter], returnType: SwiftType, body: CompoundStatement) {
        self.init(signature: .init(parameters: parameters, returnType: returnType), body: body)
    }

    public init(signature: Signature?, body: CompoundStatement) {
        self.signature = signature
        self.body = body

        super.init()

        self.body.parent = self
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        signature = try container.decodeIfPresent(Signature.self, forKey: .signature)
        body = try container.decodeStatement(CompoundStatement.self, forKey: .body)

        try super.init(from: container.superDecoder())

        self.body.parent = self
    }

    @inlinable
    public override func copy() -> BlockLiteralExpression {
        BlockLiteralExpression(
            signature: signature,
            body: body.copy()
        ).copyTypeAndMetadata(from: self)
    }

    @inlinable
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        visitor.visitBlock(self)
    }

    public override func isEqual(to other: Expression) -> Bool {
        switch other {
        case let rhs as BlockLiteralExpression:
            return self == rhs
        default:
            return false
        }
    }

    public override func hash(into hasher: inout Hasher) {
        super.hash(into: &hasher)

        hasher.combine(signature)
        hasher.combine(body)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(signature, forKey: .signature)
        try container.encodeStatement(body, forKey: .body)

        try super.encode(to: container.superEncoder())
    }

    public static func == (lhs: BlockLiteralExpression, rhs: BlockLiteralExpression) -> Bool {
        if lhs === rhs {
            return true
        }

        return lhs.signature == rhs.signature && lhs.body == rhs.body
    }

    private enum CodingKeys: String, CodingKey {
        case signature
        case returnType
        case body
    }

    public struct Signature: Equatable, Hashable, Codable, CustomStringConvertible {
        public var parameters: [BlockParameter]
        public var returnType: SwiftType

        public var description: String {
            var buff = ""
            buff += "("
            buff += parameters.map(\.description).joined(separator: ", ")
            buff += ") -> "
            buff += returnType.description
            buff += " in"
            return buff
        }

        internal init(parameters: [BlockParameter], returnType: SwiftType) {
            self.parameters = parameters
            self.returnType = returnType
        }
    }
}
public extension Expression {
    @inlinable
    var asBlock: BlockLiteralExpression? {
        cast()
    }

    @inlinable
    var isBlock: Bool {
        asBlock != nil
    }

    static func block(
        parameters: [BlockParameter] = [],
        `return` returnType: SwiftType = .void,
        body: CompoundStatement
    ) -> BlockLiteralExpression {

        BlockLiteralExpression(parameters: parameters, returnType: returnType, body: body)
    }

    static func block(
        signature: BlockLiteralExpression.Signature?,
        body: CompoundStatement
    ) -> BlockLiteralExpression {

        BlockLiteralExpression(signature: signature, body: body)
    }
}

public struct BlockParameter: Codable, Equatable, Hashable {
    public var name: String
    public var type: SwiftType

    public init(name: String, type: SwiftType) {
        self.name = name
        self.type = type
    }
}

extension BlockParameter: CustomStringConvertible {
    public var description: String {
        "\(self.name): \(type)"
    }
}
