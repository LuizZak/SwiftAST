public struct ParameterSignature: Hashable, Codable {
    public var label: String?
    public var name: String
    public var type: SwiftType
    public var isVariadic: Bool
    public var modifier: Modifier
    // TODO: Support Expression as a default value.
    public var defaultValue: Expression?

    /// Initializes a new parameter signature with a parameter that has a name
    /// and label of the same value `name`.
    ///
    /// Is equivalent to the default behavior of Swift parameters of creating a
    /// label with the same name if only a name is provided.
    public init(name: String, type: SwiftType, modifier: Modifier = .none, isVariadic: Bool = false, defaultValue: Expression? = nil) {
        self.label = name
        self.name = name
        self.type = type
        self.modifier = modifier
        self.isVariadic = isVariadic
        self.defaultValue = defaultValue
    }

    /// Initializes a new parameter signature with a given set of values.
    public init(label: String?, name: String, type: SwiftType, modifier: Modifier = .none, isVariadic: Bool = false, defaultValue: Expression? = nil) {
        self.label = label
        self.name = name
        self.type = type
        self.modifier = modifier
        self.isVariadic = isVariadic
        self.defaultValue = defaultValue
    }

    public func setParent(_ node: SyntaxNode?) {
        defaultValue?.parent = node
    }

    public enum Modifier: String, Hashable, Codable {
        case none
        case `inout`
        case borrowing
        case consuming
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: ParameterSignature.CodingKeys.self)

        self.label = try container.decodeIfPresent(String.self, forKey: .label)
        self.name = try container.decode(String.self, forKey: .name)
        self.type = try container.decode(SwiftType.self, forKey: .type)
        self.isVariadic = try container.decode(Bool.self, forKey: .isVariadic)
        self.modifier = try container.decode(ParameterSignature.Modifier.self, forKey: .modifier)
        self.defaultValue = try container.decodeExpressionIfPresent(Expression.self, forKey: .defaultValue)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: ParameterSignature.CodingKeys.self)

        try container.encodeIfPresent(self.label, forKey: .label)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.type, forKey: .type)
        try container.encode(self.isVariadic, forKey: .isVariadic)
        try container.encode(self.modifier, forKey: .modifier)
        try container.encodeExpressionIfPresent(self.defaultValue, forKey: .defaultValue)
    }

    private enum CodingKeys: CodingKey {
        case label
        case name
        case type
        case isVariadic
        case modifier
        case defaultValue
    }
}

extension ParameterSignature: CustomStringConvertible {
    public var description: String {
        var result = ""

        if let label = label {
            if label != name {
                result += "\(label) "
            }
        } else {
            result += "_ "
        }

        result += "\(name): "
        if modifier != .none {
            result += "\(modifier.rawValue) "
        }
        result += type.description

        if isVariadic {
            result += "..."
        }
        if let defaultValue {
            result += " = \(defaultValue)"
        }

        return result
    }
}
