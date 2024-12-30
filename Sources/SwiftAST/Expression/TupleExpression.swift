/// `([<label>:] <exp>, [<label>:] <exp>, ...)`
public class TupleExpression: Expression, ExpressionKindType {
    public var expressionKind: ExpressionKind {
        .tuple(self)
    }

    public var elements: [TupleElement] {
        didSet {
            oldValue.forEach { $0.setParent(nil) }
            elements.forEach { $0.setParent(self) }
        }
    }

    public override var subExpressions: [Expression] {
        elements.map(\.exp)
    }

    public override var description: String {
        "(\(elements.map(\.description).joined(separator: ", ")))"
    }

    public convenience init(elements: [Expression]) {
        self.init(elements: elements.map {
            TupleElement(label: nil, exp: $0)
        })
    }

    public init(elements: [TupleElement]) {
        self.elements = elements

        super.init()

        elements.forEach { $0.setParent(self) }
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        elements = try container.decode([TupleElement].self, forKey: .elements)

        try super.init(from: container.superDecoder())

        elements.forEach { $0.setParent(self) }
    }

    @inlinable
    public override func accept<V: ExpressionVisitor>(_ visitor: V) -> V.ExprResult {
        visitor.visitTuple(self)
    }

    @inlinable
    public override func copy() -> Expression {
        TupleExpression(elements: elements.map { $0.copy() }).copyTypeAndMetadata(from: self)
    }

    public override func isEqual(to other: Expression) -> Bool {
        switch other {
        case let rhs as TupleExpression:
            return self == rhs
        default:
            return false
        }
    }

    public override func hash(into hasher: inout Hasher) {
        super.hash(into: &hasher)

        hasher.combine(elements)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(elements, forKey: .elements)

        try super.encode(to: container.superEncoder())
    }

    public static func == (lhs: TupleExpression, rhs: TupleExpression) -> Bool {
        if lhs === rhs {
            return true
        }

        return lhs.elements == rhs.elements
    }

    private enum CodingKeys: String, CodingKey {
        case elements
    }
}
public extension Expression {
    @inlinable
    var asTuple: TupleExpression? {
        cast()
    }

    @inlinable
    var isTuple: Bool {
        asTuple != nil
    }

    static func voidTuple() -> TupleExpression {
        TupleExpression(elements: [] as [TupleElement])
    }

    static func tuple(_ elements: [Expression]) -> TupleExpression {
        TupleExpression(elements: elements)
    }

    static func tuple(_ elements: [TupleElement]) -> TupleExpression {
        TupleExpression(elements: elements)
    }
}

/// A labeled element of a tuple expression.
public struct TupleElement: Codable, Equatable, Hashable, CustomStringConvertible {
    public var label: String?
    public var exp: Expression

    public var description: String {
        if let label {
            return "\(label): \(exp)"
        }

        return exp.description
    }

    public var parent: SyntaxNode? {
        get { exp.parent }
        set { exp.parent = newValue }
    }

    public init(label: String?, exp: Expression) {
        self.label = label
        self.exp = exp
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.label = try container.decodeIfPresent(String.self, forKey: .label)
        self.exp = try container.decodeExpression(forKey: .exp)
    }

    public func copy() -> Self {
        return Self(label: label, exp: exp.copy())
    }

    public func setParent(_ parent: SyntaxNode?) {
        exp.parent = parent
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(self.label, forKey: .label)
        try container.encodeExpression(self.exp, forKey: .exp)
    }

    private enum CodingKeys: CodingKey {
        case label
        case exp
    }
}
