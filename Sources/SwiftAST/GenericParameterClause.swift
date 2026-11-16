/// A generic parameter clause for a generic declaration.
public struct GenericParameterClause: Equatable, Hashable, Codable, Sendable, CustomStringConvertible {
    public var genericParameters: [GenericTypeParameter]

    public var description: String {
        "<\(genericParameters.map(\.description).joined(separator: ", "))>"
    }

    public init(genericParameters: [GenericParameterClause.GenericTypeParameter]) {
        self.genericParameters = genericParameters
    }

    public enum GenericParameter: Equatable, Hashable, Codable, Sendable, CustomStringConvertible {
        case literal(GenericLiteralParameter)
        case type(GenericTypeParameter)

        public var description: String {
            switch self {
            case .literal(let literal):
                return literal.description

            case .type(let type):
                return type.description
            }
        }
    }

    public struct GenericLiteralParameter: Equatable, Hashable, Codable, Sendable, CustomStringConvertible {
        public var name: String
        public var type: SwiftType

        public var description: String {
            "let \(name): \(type)"
        }

        public init(name: String, type: SwiftType) {
            self.name = name
            self.type = type
        }
    }

    public struct GenericTypeParameter: Equatable, Hashable, Codable, Sendable, CustomStringConvertible {
        public var isParameterPack: Bool
        public var typeName: String
        public var typeConstraint: TypeConstraint?

        public var description: String {
            let leadType: String
            if isParameterPack {
                leadType = "each \(typeName)"
            } else {
                leadType = typeName
            }

            if let typeConstraint {
                return "\(leadType): \(typeConstraint)"
            }

            return leadType
        }

        public init(isParameterPack: Bool = false, typeName: String, typeConstraint: TypeConstraint? = nil) {
            self.isParameterPack = isParameterPack
            self.typeName = typeName
            self.typeConstraint = typeConstraint
        }

        public enum TypeConstraint: Equatable, Hashable, Codable, Sendable, CustomStringConvertible {
            case nominal(NominalSwiftType)
            case protocolComposition(ProtocolCompositionSwiftType)

            public var description: String {
                switch self {
                case .nominal(let nominal):
                    return nominal.description

                case .protocolComposition(let protocolComposition):
                    return protocolComposition.map(\.description).joined(separator: " & ")
                }
            }
        }
    }
}

extension GenericParameterClause: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: GenericTypeParameter...) {
        self.init(genericParameters: elements)
    }
}

extension GenericParameterClause.GenericTypeParameter: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(typeName: value)
    }
}
