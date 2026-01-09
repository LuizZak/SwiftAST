/// A generic parameter clause for a generic declaration.
public struct GenericParameterClause: Equatable, Hashable, Codable {
    public var genericParameters: [GenericParameter]

    public init(genericParameters: [GenericParameterClause.GenericParameter]) {
        self.genericParameters = genericParameters
    }

    public struct GenericParameter: Equatable, Hashable, Codable {
        public var isParameterPack: Bool
        public var typeName: String
        public var typeConstraint: TypeConstraint?

        public init(isParameterPack: Bool = false, typeName: String, typeConstraint: TypeConstraint? = nil) {
            self.isParameterPack = isParameterPack
            self.typeName = typeName
            self.typeConstraint = typeConstraint
        }

        public enum TypeConstraint: Equatable, Hashable, Codable {
            case nominal(NominalSwiftType)
            case protocolComposition(ProtocolCompositionSwiftType)
        }
    }
}

extension GenericParameterClause: CustomStringConvertible {
    public var description: String {
        "<\(genericParameters.map(\.description).joined(separator: ", "))>"
    }
}
extension GenericParameterClause: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: GenericParameter...) {
        self.init(genericParameters: elements)
    }
}

extension GenericParameterClause.GenericParameter: CustomStringConvertible {
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
}
extension GenericParameterClause.GenericParameter: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(typeName: value)
    }
}

extension GenericParameterClause.GenericParameter.TypeConstraint: CustomStringConvertible {
    public var description: String {
        switch self {
        case .nominal(let nominal):
            return nominal.description

        case .protocolComposition(let protocolComposition):
            return protocolComposition.map(\.description).joined(separator: " & ")
        }
    }
}
