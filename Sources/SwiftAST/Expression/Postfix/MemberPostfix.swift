/// `<base>.<member>`/`<base>.<member>(<arg-names>)`
public final class MemberPostfix: Postfix {
    public let name: String
    public let argumentNames: [ArgumentName]?

    public override var description: String {
        if let argumentNames {
            "\(super.description).\(name)(\(argumentNames.map(\.description).joined()))"
        } else {
            "\(super.description).\(name)"
        }
    }

    public init(name: String, argumentNames: [ArgumentName]?) {
        self.name = name
        self.argumentNames = argumentNames

        super.init()
    }

    public required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        try self.init(
            name: container.decode(String.self, forKey: .name),
            argumentNames: container.decodeIfPresent([ArgumentName].self, forKey: .argumentNames)
        )
    }

    public override func copy() -> MemberPostfix {
        MemberPostfix(name: name, argumentNames: argumentNames).copyTypeAndMetadata(from: self)
    }

    public override func isEqual(to other: Postfix) -> Bool {
        switch other {
        case let rhs as MemberPostfix:
            return self == rhs
        default:
            return false
        }
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(argumentNames, forKey: .argumentNames)

        try super.encode(to: container.superEncoder())
    }

    public static func == (lhs: MemberPostfix, rhs: MemberPostfix) -> Bool {
        if lhs === rhs {
            return true
        }

        return lhs.optionalAccessKind == rhs.optionalAccessKind
            && lhs.name == rhs.name
            && lhs.argumentNames == rhs.argumentNames
    }

    public struct ArgumentName: Equatable, Codable, CustomStringConvertible {
        public var identifier: String

        public var description: String {
            "\(identifier):"
        }

        public init(identifier: String) {
            self.identifier = identifier
        }
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case argumentNames
    }
}
public extension Postfix {
    static func member(_ name: String) -> MemberPostfix {
        MemberPostfix(name: name, argumentNames: nil)
    }

    static func member(_ name: String, argumentNames: [MemberPostfix.ArgumentName]) -> MemberPostfix {
        MemberPostfix(name: name, argumentNames: argumentNames)
    }

    @inlinable
    var asMember: MemberPostfix? {
        self as? MemberPostfix
    }

    @inlinable
    var isMember: Bool {
        asMember != nil
    }
}
// Helper casting getter extensions to postfix expression
public extension PostfixExpression {
    @inlinable
    var member: MemberPostfix? {
        op as? MemberPostfix
    }

    @inlinable
    var isMember: Bool {
        member != nil
    }
}
