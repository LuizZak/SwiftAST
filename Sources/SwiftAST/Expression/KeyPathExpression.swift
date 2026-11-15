/// `\[<type>].<keyPathComponents>`
public class KeyPathExpression: Expression {
    public var baseType: SwiftType?
    public var keyPathComponents: KeyPathComponents {
        didSet { keyPathComponents.setParent(nil); keyPathComponents.setParent(self) }
    }

    public override var subExpressions: [Expression] {
        keyPathComponents.subExpressions
    }

    public override var description: String {
        if let baseType {
            return "\\\(baseType).\(keyPathComponents)"
        }

        return "\\.\(keyPathComponents)"
    }

    public init(baseType: SwiftType? = nil, keyPathComponents: KeyPathExpression.KeyPathComponents) {
        self.baseType = baseType
        self.keyPathComponents = keyPathComponents

        super.init()

        keyPathComponents.setParent(self)
    }

    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        baseType = try container.decode(SwiftType.self, forKey: .baseType)
        keyPathComponents = try container.decode(KeyPathComponents.self, forKey: .keyPathComponents)

        try super.init(from: container.superDecoder())

        keyPathComponents.setParent(self)
    }

    @inlinable
    public override func copy() -> KeyPathExpression {
        KeyPathExpression(baseType: baseType, keyPathComponents: keyPathComponents.copy())
    }

    public override func isEqual(to other: Expression) -> Bool {
        switch other {
        case let rhs as KeyPathExpression:
            return self == rhs

        default:
            return false
        }
    }

    public static func == (lhs: KeyPathExpression, rhs: KeyPathExpression) -> Bool {
        lhs.baseType == rhs.baseType && lhs.keyPathComponents == rhs.keyPathComponents
    }

    enum CodingKeys: String, CodingKey {
        case baseType
        case keyPathComponents
    }

    public indirect enum KeyPathComponents: Codable, Hashable, CustomStringConvertible, ExpressionComponent {
        case base(KeyPathComponent)
        case nested(KeyPathComponents, KeyPathComponent)

        public var description: String {
            switch self {
            case .base(let item):
                return "\(item)"

            case .nested(let inner, let item):
                return "\(inner).\(item)"
            }
        }

        public var subExpressions: [Expression] {
            switch self {
            case .base(let item):
                return item.subExpressions

            case .nested(let inner, let item):
                return inner.subExpressions + item.subExpressions
            }
        }

        public func setParent(_ syntaxNode: SyntaxNode?) {
            switch self {
            case .base(let item):
                item.setParent(syntaxNode)

            case .nested(let inner, let item):
                inner.setParent(syntaxNode)
                item.setParent(syntaxNode)
            }
        }

        public func copy() -> KeyPathComponents {
            switch self {
            case .base(let item):
                return .base(item.copy())

            case .nested(let inner, let item):
                return .nested(inner.copy(), item.copy())
            }
        }
    }

    public enum KeyPathComponent: Codable, Hashable, CustomStringConvertible, ExpressionComponent {
        case identifier(String, KeyPathPostfixes? = nil)
        case postfixes(KeyPathPostfixes)

        public var description: String {
            switch self {
            case .identifier(let identifier, let postfixes?):
                return "\(identifier)\(postfixes)"

            case .identifier(let identifier, nil):
                return "\(identifier)"

            case .postfixes(let postfixes):
                return "\(postfixes)"
            }
        }

        public var subExpressions: [Expression] {
            switch self {
            case .identifier(_, let postfixes?):
                return postfixes.subExpressions

            case .identifier(_, nil):
                return []

            case .postfixes(let postfixes):
                return postfixes.subExpressions
            }
        }

        public func setParent(_ syntaxNode: SyntaxNode?) {
            switch self {
            case .identifier(_, let postfixes?):
                postfixes.setParent(syntaxNode)

            case .identifier(_, nil):
                break

            case .postfixes(let postfixes):
                postfixes.setParent(syntaxNode)
            }
        }

        public func copy() -> KeyPathComponent {
            switch self {
            case .identifier(let identifier, let postfixes?):
                return .identifier(identifier, postfixes.copy())

            case .identifier(let identifier, nil):
                return .identifier(identifier, nil)

            case .postfixes(let postfixes):
                return .postfixes(postfixes.copy())
            }
        }
    }

    public indirect enum KeyPathPostfixes: Codable, Hashable, CustomStringConvertible, ExpressionComponent {
        case base(KeyPathPostfix)
        case nested(KeyPathPostfixes, KeyPathPostfix)

        public var description: String {
            switch self {
            case .base(let item):
                return item.description

            case .nested(let inner, let item):
                return "\(inner)\(item)"
            }
        }

        public var subExpressions: [Expression] {
            switch self {
            case .base(let item):
                return item.subExpressions

            case .nested(let inner, let item):
                return inner.subExpressions + item.subExpressions
            }
        }

        public func setParent(_ syntaxNode: SyntaxNode?) {
            switch self {
            case .base(let item):
                item.setParent(syntaxNode)

            case .nested(let inner, let item):
                inner.setParent(syntaxNode)
                item.setParent(syntaxNode)
            }
        }

        public func copy() -> KeyPathPostfixes {
            switch self {
            case .base(let item):
                return .base(item.copy())

            case .nested(let inner, let item):
                return .nested(inner.copy(), item.copy())
            }
        }
    }

    public enum KeyPathPostfix: Codable, Hashable, CustomStringConvertible, ExpressionComponent {
        case forceUnwrap
        case safeUnwrap
        case `subscript`([FunctionArgument])

        public var description: String {
            switch self {
            case .forceUnwrap:
                return "!"

            case .safeUnwrap:
                return "?"

            case .subscript(let arguments):
                return "[\(arguments.map(\.description).joined(separator: ", "))]"
            }
        }

        public var subExpressions: [Expression] {
            switch self {
            case .forceUnwrap:
                return []

            case .safeUnwrap:
                return []

            case .subscript(let arguments):
                return arguments.map(\.expression)
            }
        }

        public func setParent(_ syntaxNode: SyntaxNode?) {
            switch self {
            case .forceUnwrap, .safeUnwrap:

                break

            case .subscript(let arguments):
                for arg in arguments {
                    arg.expression.parent = syntaxNode
                }
            }
        }

        public func copy() -> KeyPathPostfix {
            switch self {
            case .forceUnwrap:
                return .forceUnwrap

            case .safeUnwrap:
                return .safeUnwrap

            case .subscript(let arguments):
                return .subscript(arguments.map({ $0.copy() }))
            }
        }
    }
}

public extension Expression {
    /// Returns `self as? KeyPathExpression`.
    @inlinable
    var asKeyPath: KeyPathExpression? {
        cast()
    }

    /// Returns `true` if this `Expression` is an instance of `KeyPathExpression`
    /// class.
    @inlinable
    var isKeyPath: Bool {
        asKeyPath != nil
    }

    /// Creates a `KeyPathExpression` instance with a nil base type and the given
    /// key path components.
    static func keyPath(
        _ keyPathComponents: KeyPathExpression.KeyPathComponents
    ) -> KeyPathExpression {

        KeyPathExpression(baseType: nil, keyPathComponents: keyPathComponents)
    }

    /// Creates a `KeyPathExpression` instance using the given base type and
    /// key path components.
    static func keyPath(
        baseType: SwiftType,
        _ keyPathComponents: KeyPathExpression.KeyPathComponents
    ) -> KeyPathExpression {

        KeyPathExpression(baseType: baseType, keyPathComponents: keyPathComponents)
    }
}

public extension KeyPathExpression.KeyPathComponents {
    func appendingComponent(_ component: KeyPathExpression.KeyPathComponent) -> Self {
        return .nested(self, component)
    }
}

public extension KeyPathExpression.KeyPathPostfixes {
    func appendingPostfix(_ pf: KeyPathExpression.KeyPathPostfix) -> Self {
        return .nested(self, pf)
    }
}
