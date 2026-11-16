/// A generic `where` clause for a generic declaration.
public struct GenericWhereClause: Equatable, Hashable, Codable, Sendable, CustomStringConvertible {
    public var requirements: [Requirement]

    public var description: String {
        "where \(requirements.map(\.description).joined(separator: ", "))"
    }

    public init(requirements: [GenericWhereClause.Requirement]) {
        self.requirements = requirements
    }

    public enum Requirement: Equatable, Hashable, Codable, Sendable, CustomStringConvertible {
        case conformanceRequirement(TypeConstraint, ConformanceBase)
        case sameTypeRequirement(TypeConstraint, SwiftType)
        case literalRequirement(LiteralConstraint, Int)

        public var description: String {
            switch self {
            case .conformanceRequirement(let base, let derived):
                return "\(base): \(derived)"

            case .sameTypeRequirement(let base, let derived):
                return "\(base) == \(derived)"

            case .literalRequirement(let base, let literal):
                return "\(base) == \(literal)"
            }
        }

        public enum LiteralConstraint: Equatable, Hashable, Codable, Sendable, CustomStringConvertible {
            case nominal(NominalSwiftType)
            case nested(NestedSwiftType)

            public var description: String {
                switch self {
                case .nominal(let nominal):
                    return nominal.description

                case .nested(let nested):
                    return nested.description
                }
            }
        }

        public enum TypeConstraint: Equatable, Hashable, Codable, Sendable, CustomStringConvertible {
            case parameterPack(ParameterPackType)
            case nominal(NominalSwiftType)
            case nested(NestedSwiftType)

            public var description: String {
                switch self {
                case .parameterPack(let parameterPack):
                    return parameterPack.description

                case .nominal(let nominal):
                    return nominal.description

                case .nested(let nested):
                    return nested.description
                }
            }
        }

        public enum ConformanceBase: Equatable, Hashable, Codable, Sendable, CustomStringConvertible {
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

extension GenericWhereClause: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Requirement...) {
        self.init(requirements: elements)
    }
}

extension GenericWhereClause.Requirement.LiteralConstraint: ExpressibleByStringLiteral {
    /// Initializes a literal constraint requirement that is a nominal type with
    /// a given string literal.
    public init(stringLiteral value: StringLiteralType) {
        self = .nominal(.init(stringLiteral: value))
    }
}

extension GenericWhereClause.Requirement.TypeConstraint: ExpressibleByStringLiteral {
    /// Initializes a type constraint requirement that is a nominal type with a
    /// given string literal.
    public init(stringLiteral value: StringLiteralType) {
        self = .nominal(.init(stringLiteral: value))
    }
}
