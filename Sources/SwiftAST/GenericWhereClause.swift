/// A generic `where` clause for a generic declaration.
public struct GenericWhereClause: Equatable, Hashable, Codable {
    public var requirements: [Requirement]

    public init(requirements: [GenericWhereClause.Requirement]) {
        self.requirements = requirements
    }

    public enum Requirement: Equatable, Hashable, Codable {
        case conformanceRequirement(TypeConstraint, ConformanceBase)
        case sameTypeRequirement(TypeConstraint, SwiftType)

        public enum TypeConstraint: Equatable, Hashable, Codable {
            case nominal(NominalSwiftType)
            case nested(NestedSwiftType)
        }

        public enum ConformanceBase: Equatable, Hashable, Codable {
            case nominal(NominalSwiftType)
            case protocolComposition(ProtocolCompositionSwiftType)
        }
    }
}

extension GenericWhereClause: CustomStringConvertible {
    public var description: String {
        "where \(requirements.map(\.description).joined(separator: ", "))"
    }
}
extension GenericWhereClause: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Requirement...) {
        self.init(requirements: elements)
    }
}

extension GenericWhereClause.Requirement: CustomStringConvertible {
    public var description: String {
        switch self {
        case .conformanceRequirement(let base, let derived):
            return "\(base): \(derived)"

        case .sameTypeRequirement(let base, let derived):
            return "\(base) == \(derived)"
        }
    }
}

extension GenericWhereClause.Requirement.TypeConstraint: CustomStringConvertible {
    public var description: String {
        switch self {
        case .nominal(let nominal):
            return nominal.description

        case .nested(let nested):
            return nested.description
        }
    }
}

extension GenericWhereClause.Requirement.TypeConstraint: ExpressibleByStringLiteral {
    /// Initializes a type constraint requirement that is a nominal type with a
    /// given string literal.
    public init(stringLiteral value: StringLiteralType) {
        self = .nominal(.init(stringLiteral: value))
    }
}

extension GenericWhereClause.Requirement.ConformanceBase: CustomStringConvertible {
    public var description: String {
        switch self {
        case .nominal(let nominal):
            return nominal.description

        case .protocolComposition(let protocolComposition):
            return protocolComposition.map(\.description).joined(separator: " & ")
        }
    }
}
