/// Defines the ownership of a variable storage
public enum Ownership: String, Hashable, Codable, Sendable {
    case strong
    case weak
    case unownedSafe = "unowned(safe)"
    case unownedUnsafe = "unowned(unsafe)"
}
