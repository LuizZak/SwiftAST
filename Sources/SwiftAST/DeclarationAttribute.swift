/// Represents a Swift declaration attribute.
public struct DeclarationAttribute {
    /// The name of the attribute, minus the leading `@` sign.
    public var name: String

    /// The arguments for the attribute. Can be nil, if the attribute should have
    /// no arguments.
    public var arguments: [FunctionArgument]?

    public init(name: String, arguments: [FunctionArgument]? = nil) {
        self.name = name
        self.arguments = arguments
    }
}

extension DeclarationAttribute: CustomStringConvertible {
    public var description: String {
        if let arguments = arguments {
            return "@\(name)(\(arguments))"
        }

        return "@\(name)"
    }
}

extension DeclarationAttribute: Equatable { }
extension DeclarationAttribute: Hashable { }
extension DeclarationAttribute: Encodable { }
extension DeclarationAttribute: Decodable { }
