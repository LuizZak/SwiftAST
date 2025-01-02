public struct ParameterSignature: Hashable, Codable {
    public var label: String?
    public var name: String
    public var type: SwiftType
    public var isVariadic: Bool
    public var modifier: Modifier
    // TODO: Support Expression as a default value.
    public var hasDefaultValue: Bool

    /// Initializes a new parameter signature with a parameter that has a name
    /// and label of the same value `name`.
    ///
    /// Is equivalent to the default behavior of Swift parameters of creating a
    /// label with the same name if only a name is provided.
    public init(name: String, type: SwiftType, modifier: Modifier = .none, isVariadic: Bool = false, hasDefaultValue: Bool = false) {
        self.label = name
        self.name = name
        self.type = type
        self.modifier = modifier
        self.isVariadic = isVariadic
        self.hasDefaultValue = hasDefaultValue
    }

    /// Initializes a new parameter signature with a given set of values.
    public init(label: String?, name: String, type: SwiftType, modifier: Modifier = .none, isVariadic: Bool = false, hasDefaultValue: Bool = false) {
        self.label = label
        self.name = name
        self.type = type
        self.modifier = modifier
        self.isVariadic = isVariadic
        self.hasDefaultValue = hasDefaultValue
    }

    public enum Modifier: String, Hashable, Codable {
        case none
        case `inout`
        case borrowing
        case consuming
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
        if hasDefaultValue {
            result += " = default"
        }

        return result
    }
}
