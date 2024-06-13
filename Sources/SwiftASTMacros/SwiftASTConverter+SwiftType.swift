import SwiftSyntax

// MARK: - SwiftType conversion

extension SwiftASTConverter {
    /// Returns an expression that resolves to `SwiftType`, constructing the given
    /// type syntax structure.
    ///
    /// Unsupported type conversions will throw an error.
    static func convertType(_ type: TypeSyntax) throws -> ExprSyntax {
        if let type = type.as(IdentifierTypeSyntax.self) {
            let nominalType = try asNominalSwiftType(type)

            return """
            SwiftType.nominal(\(nominalType))
            """
        }
        if let type = type.as(MemberTypeSyntax.self) {
            let expr = try asNestedSwiftType(type)

            return """
            SwiftType.nested(\(expr))
            """
        }
        if let type = type.as(CompositionTypeSyntax.self) {
            let expr = try asProtocolCompositionSwiftType(type)

            return """
            SwiftType.protocolComposition(\(expr))
            """
        }
        if let type = type.as(TupleTypeSyntax.self) {
            if type.elements.count == 1 {
                for element in type.elements {
                    return try convertType(element.type)
                }
            }

            let tupleType = try asTupleSwiftType(type)

            return """
            SwiftType.tuple(\(tupleType))
            """
        }
        if let type = type.as(AttributedTypeSyntax.self) {
            return try convertAttributedType(type)
        }
        if let type = type.as(FunctionTypeSyntax.self) {
            let blockType = try asBlockSwiftType(type)

            return """
            SwiftType.block(\(blockType))
            """
        }
        if let type = type.as(MetatypeTypeSyntax.self) {
            let inner = try convertType(type.baseType)

            guard type.metatypeSpecifier.tokenKind == .keyword(.Type) else {
                throw type.ext_error(message: """
                <type>.Protocol meta-types are not supported by SwiftType, only <type>.Type.
                """)
            }

            return """
            SwiftType.metatype(for: \(inner))
            """
        }
        if let type = type.as(OptionalTypeSyntax.self) {
            let inner = try convertType(type.wrappedType)

            return """
            SwiftType.optional(\(inner))
            """
        }
        if let type = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            let inner = try convertType(type.wrappedType)

            return """
            SwiftType.implicitUnwrappedOptional(\(inner))
            """
        }
        if let type = type.as(ArrayTypeSyntax.self) {
            return """
            SwiftType.array(\(try convertType(type.element)))
            """
        }
        if let type = type.as(DictionaryTypeSyntax.self) {
            let keyType = try convertType(type.key)
            let valueType = try convertType(type.value)

            return """
            SwiftType.dictionary(key: \(keyType), value: \(valueType))
            """
        }

        throw type.ext_error(message: "Unsupported type")
    }

    /// Returns an expression that resolves to `NestedSwiftType`.
    private static func asNestedSwiftType(_ memberType: MemberTypeSyntax) throws -> ExprSyntax {
        var elements: [ExprSyntax] = []

        var nextType: TypeSyntax? = TypeSyntax(memberType)

        while let current = nextType {
            let _next: TypeSyntax?
            if let memberType = current.as(MemberTypeSyntax.self) {
                elements.append(
                    try asNominalSwiftType(memberType.name, memberType.genericArgumentClause)
                )

                _next = memberType.baseType

            } else if let identifierType = current.as(IdentifierTypeSyntax.self) {
                elements.append(
                    try asNominalSwiftType(identifierType)
                )

                _next = nil
            } else {
                throw current.ext_error(
                    message: """
                    Unsupported base type in member type syntax. \
                    Expected: \(IdentifierTypeSyntax.self) or \(MemberTypeSyntax.self)
                    """
                )
            }

            nextType = _next
        }

        return """
        NestedSwiftType.fromCollection(\(ArrayExprSyntax(expressions: elements)))
        """
    }

    /// Returns an expression that resolves to `NominalSwiftType`.
    private static func asNominalSwiftType(_ type: TypeSyntax) throws -> ExprSyntax {
        if let type = type.as(IdentifierTypeSyntax.self) {
            return try asNominalSwiftType(type)
        }

        throw type.ext_error(
            message: "Expected \(IdentifierTypeSyntax.self) type, found \(type.kind)"
        )
    }

    /// Returns an expression that resolves to `NominalSwiftType`.
    private static func asNominalSwiftType(_ type: IdentifierTypeSyntax) throws -> ExprSyntax {
        return try asNominalSwiftType(type.name, type.genericArgumentClause)
    }

    /// Returns an expression that resolves to `NominalSwiftType`.
    private static func asNominalSwiftType(
        _ name: TokenSyntax,
        _ genericArgumentClause: GenericArgumentClauseSyntax?
    ) throws -> ExprSyntax {

        if let genericArgs = genericArgumentClause {
            let args = try genericArgs.arguments.map {
                try convertType($0.argument)
            }

            return """
            NominalSwiftType.generic(
                \(stringLiteral(name)),
                parameters: \(ArrayExprSyntax(expressions: args))
            )
            """
        }

        return """
        NominalSwiftType.typeName(\(stringLiteral(name)))
        """
    }

    /// Returns an expression that resolves to `TupleSwiftType`.
    private static func asTupleSwiftType(_ tupleType: TupleTypeSyntax) throws -> ExprSyntax {
        if tupleType.elements.count == 1 {
            throw tupleType.ext_error(message: """
            Internal error: Attempted to create TupleSwiftType with only one element?
            """)
        }

        if tupleType.elements.isEmpty {
            return """
            TupleSwiftType.empty
            """
        }

        let elements = try tupleType.elements.map { element in
            try convertType(element.type)
        }

        return """
        TupleSwiftType.types(\(ArrayExprSyntax(expressions: elements)))
        """
    }

    /// Returns an expression that resolves to `BlockSwiftType`.
    private static func asBlockSwiftType(_ functionType: FunctionTypeSyntax) throws -> ExprSyntax {
        guard functionType.effectSpecifiers == nil || functionType.effectSpecifiers?.trimmed.description == "" else {
            throw functionType.ext_error(message: """
            BlockSwiftType does not currently support effect specifiers of function type syntaxes.
            """)
        }

        let returnType = try convertType(functionType.returnClause.type)
        var parameters: [ExprSyntax] = []

        for parameter in functionType.parameters {
            if let firstName = parameter.firstName {
                throw firstName.ext_error(message: """
                BlockSwiftType does not currently support argument names of function type syntaxes.
                """)
            }
            if let secondName = parameter.secondName {
                throw secondName.ext_error(message: """
                BlockSwiftType does not currently support argument names of function type syntaxes.
                """)
            }
            if let inoutKeyword = parameter.inoutKeyword {
                throw inoutKeyword.ext_error(message: """
                BlockSwiftType does not currently support inout arguments of function type syntaxes.
                """)
            }
            if let ellipsis = parameter.ellipsis {
                throw ellipsis.ext_error(message: """
                BlockSwiftType does not currently support ellipsis of function type syntaxes.
                """)
            }

            let parameterType = try convertType(parameter.type)
            parameters.append(parameterType)
        }

        return """
        BlockSwiftType(
            returnType: \(returnType),
            parameters: \(ArrayExprSyntax(expressions: parameters))
        )
        """
    }

    /// Returns an expression that resolves to `ProtocolCompositionSwiftType`.
    private static func asProtocolCompositionSwiftType(
        _ compositionType: CompositionTypeSyntax
    ) throws -> ExprSyntax {

        var elements: [ExprSyntax] = []
        for element in compositionType.elements {
            if let memberType = element.type.as(MemberTypeSyntax.self) {
                let expr = try asNestedSwiftType(memberType)

                elements.append("""
                ProtocolCompositionComponent.nested(\(expr))
                """)
            } else if let identifierType = element.type.as(IdentifierTypeSyntax.self) {
                let expr = try asNominalSwiftType(identifierType)

                elements.append("""
                ProtocolCompositionComponent.nominal(\(expr))
                """)
            } else {
                throw element.type.ext_error(
                    message: """
                    Unsupported type in protocol composition type. \
                    Expected: \(IdentifierTypeSyntax.self) or \(MemberTypeSyntax.self)
                    """
                )
            }
        }

        return """
            ProtocolCompositionSwiftType.fromCollection(\(ArrayExprSyntax(expressions: elements)))
            """
    }

    /// Returns an expression that resolves to `SwiftType`.
    private static func convertAttributedType(_ attributedType: AttributedTypeSyntax) throws -> ExprSyntax {
        if let specifier = attributedType.specifier {
            throw specifier.ext_error(message: """
            SwiftType does not support type specifiers.
            """)
        }

        guard let functionType = attributedType.baseType.as(FunctionTypeSyntax.self) else {
            throw attributedType.baseType.ext_error(message: """
            SwiftType does not support attributes in the given type.
            """)
        }

        let blockType = try asBlockSwiftType(functionType)

        let attributes = try attributedType.attributes.map(convertBlockAttribute)

        return """
        SwiftType.block(
            \(blockType).addingAttributes(\(ArrayExprSyntax(expressions: attributes)))
        )
        """
    }

    /// Returns an expression that resolves to `BlockTypeAttribute`.
    private static func convertBlockAttribute(_ attribute: AttributeListSyntax.Element) throws -> ExprSyntax {
        switch attribute {
        case .attribute(let attribute):
            return try convertBlockAttribute(attribute)
        case .ifConfigDecl:
            throw attribute.ext_error(message: """
            SwiftType only supports @autoclosure, @escaping, @convention(c), @convention(block) function type annotations.
            """)
        }
    }

    /// Returns an expression that resolves to `BlockTypeAttribute`.
    private static func convertBlockAttribute(_ attribute: AttributeSyntax) throws -> ExprSyntax {
        let desc = attribute.trimmed.description

        switch desc {
        case "@autoclosure":
            return "BlockTypeAttribute.autoclosure"
        case "@escaping":
            return "BlockTypeAttribute.escaping"
        case "@convention(c)":
            return "BlockTypeAttribute.convention(BlockTypeAttribute.Convention.c)"
        case "@convention(block)":
            return "BlockTypeAttribute.convention(BlockTypeAttribute.Convention.block)"
        default:
            throw attribute.ext_error(message: """
            SwiftType only supports @autoclosure, @escaping, @convention(c), @convention(block) function type annotations.
            """)
        }
    }
}
