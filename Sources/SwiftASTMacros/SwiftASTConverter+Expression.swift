import SwiftSyntax

// MARK: - Expression conversion

extension SwiftASTConverter {
    static func convertExpression(_ expr: ExprSyntax) throws -> ExprSyntax {
        if let expr = expr.as(ArrayExprSyntax.self) {
            return try convertArrayLiteral(expr)
        }
        if let expr = expr.as(InfixOperatorExprSyntax.self) {
            return try convertBinary(expr)
        }
        if let expr = expr.as(ClosureExprSyntax.self) {
            return try convertBlockLiteral(expr)
        }
        if let expr = expr.as(AsExprSyntax.self) {
            return try convertCast(expr)
        }
        if let expr = expr.as(DictionaryExprSyntax.self) {
            return try convertDictionaryLiteral(expr)
        }
        if let expr = expr.as(DeclReferenceExprSyntax.self) {
            return try convertIdentifier(expr)
        }
        if let expr = expr.as(TupleExprSyntax.self) {
            return try convertTuple(expr)
        }

        // Postfix
        if let expr = expr.as(MemberAccessExprSyntax.self) {
            return try convertPostfix(expr)
        }
        if let expr = expr.as(FunctionCallExprSyntax.self) {
            return try convertPostfix(expr)
        }
        if let expr = expr.as(SubscriptCallExprSyntax.self) {
            return try convertPostfix(expr)
        }
        if let expr = expr.as(OptionalChainingExprSyntax.self) {
            return try convertPostfix(expr)
        }
        if let expr = expr.as(ForceUnwrapExprSyntax.self) {
            return try convertPostfix(expr)
        }

        if let expr = expr.as(PrefixOperatorExprSyntax.self) {
            return try convertPrefix(expr)
        }
        if let expr = expr.as(TernaryExprSyntax.self) {
            return try convertTernary(expr)
        }
        if let expr = expr.as(IsExprSyntax.self) {
            return try convertTypeCheck(expr)
        }
        if let expr = expr.as(TryExprSyntax.self) {
            return try convertTryExpression(expr)
        }

        if let expr = expr.as(IfExprSyntax.self) {
            return try convertIf(expr)
        }

        if let expr = expr.as(SwitchExprSyntax.self) {
            throw expr.ext_error(message: """
            Switch statements in place of expressions are not supported by SwiftAST's Expression type.
            """)
        }

        // Try constant as a fallback
        return try convertConstant(expr)
    }

    static func convertArrayLiteral(_ expr: ArrayExprSyntax) throws -> ExprSyntax {
        var expressions: [ExprSyntax] = []

        for element in expr.elements {
            let value = try convertExpression(element.expression)

            expressions.append(value)
        }

        return """
        ArrayLiteralExpression(items: \(ArrayExprSyntax(expressions: expressions)))
        """
    }

    static func convertBinary(_ expr: InfixOperatorExprSyntax) throws -> ExprSyntax {
        let lhs = try convertExpression(expr.leftOperand)
        let tok = try _SwiftOperator.tryFrom(expr.operator)
        let rhs = try convertExpression(expr.rightOperand)

        // Detect assignment expressions
        if tok.isAssignment {
            return """
            AssignmentExpression(
                lhs: \(lhs),
                op: \(tok.asSwiftOperatorExpr),
                rhs: \(rhs)
            )
            """
        } else {
            return """
            BinaryExpression(
                lhs: \(lhs),
                op: \(tok.asSwiftOperatorExpr),
                rhs: \(rhs)
            )
            """
        }
    }

    static func convertBlockLiteral(_ expr: ClosureExprSyntax) throws -> ExprSyntax {
        var parameters: [ExprSyntax] = []
        var returnType: ExprSyntax = swiftTypeVoid

        if let signature = expr.signature {
            guard let returnClause = signature.returnClause else {
                throw signature.ext_error(message: """
                Blocks that provide a signature must provide a return type.
                """)
            }
            guard let parameterClause = signature.parameterClause else {
                throw signature.ext_error(message: """
                Blocks that provide a signature must provide a parameter set with labels and types.
                """)
            }

            returnType = try convertType(returnClause.type)

            switch parameterClause {
            case .simpleInput(let input):
                throw input.ext_error(message: """
                Blocks that provide a signature must provide a parameter set with labels and types.
                """)

            case .parameterClause(let params):
                for param in params.parameters {
                    if let secondName = param.secondName {
                        throw secondName.ext_error(message: """
                        BlockLiteralExpression doesn't support parameters with second names.
                        """)
                    }
                    guard let type = param.type else {
                        throw param.ext_error(message: """
                        BlockLiteralExpression doesn't support parameters with no explicit type.
                        """)
                    }

                    let blockParameter: ExprSyntax = """
                    BlockParameter(
                        name: \(stringLiteral(param.firstName)),
                        type: \(try convertType(type))
                    )
                    """

                    parameters.append(blockParameter)
                }
            }
        }

        let body = try convertCompound(expr.statements)

        return """
        BlockLiteralExpression(
            parameters: \(ArrayExprSyntax(expressions: parameters)),
            returnType: \(returnType),
            body: \(body)
        )
        """
    }

    static func convertCast(_ expr: AsExprSyntax) throws -> ExprSyntax {
        let isOptionalCast: ExprSyntax

        if let mark = expr.questionOrExclamationMark {
            if mark.trimmed.description == "?" {
                isOptionalCast = "true"
            } else if mark.trimmed.description == "!" {
                throw mark.ext_error(message: """
                CastExpression does not currently support forced-cast expressions.
                """)
            } else {
                isOptionalCast = "false"
            }
        } else {
            isOptionalCast = "false"
        }

        return """
        CastExpression(
            exp: \(try convertExpression(expr.expression)),
            type: \(try convertType(expr.type)),
            isOptionalCast: \(isOptionalCast)
        )
        """
    }

    static func convertConstant(_ expr: ExprSyntax) throws -> ExprSyntax {
        if let expr = expr.as(IntegerLiteralExprSyntax.self) {
            return """
            ConstantExpression.constant(
                Constant.int(\(expr), .decimal)
            )
            """
        }
        if let expr = expr.as(FloatLiteralExprSyntax.self) {
            return """
            ConstantExpression(
                constant: Constant.double(\(expr))
            )
            """
        }
        if let expr = expr.as(BooleanLiteralExprSyntax.self) {
            return """
            ConstantExpression(
                constant: Constant.boolean(\(expr))
            )
            """
        }
        if expr.is(NilLiteralExprSyntax.self) {
            return """
            ConstantExpression(constant: Constant.nil)
            """
        }
        if let expr = expr.as(StringLiteralExprSyntax.self) {
            return """
            ConstantExpression(
                constant: Constant.string(\(expr))
            )
            """
        }

        throw expr.ext_error(message: """
        Attempted to create ConstantExpression with unsupported expression kind \(expr.kind)
        """)
    }

    static func convertDictionaryLiteral(_ expr: DictionaryExprSyntax) throws -> ExprSyntax {
        switch expr.content {
        case .colon:
            return """
            DictionaryLiteralExpression(pairs: [])
            """
        case .elements(let elements):
            var expressions: [ExprSyntax] = []

            for element in elements {
                let key = try convertExpression(element.key)
                let value = try convertExpression(element.value)

                expressions.append("""
                ExpressionDictionaryPair(key: \(key), value: \(value))
                """)
            }

            return """
            DictionaryLiteralExpression(pairs: \(ArrayExprSyntax(expressions: expressions)))
            """
        }
    }

    static func convertIdentifier(_ expr: DeclReferenceExprSyntax) throws -> ExprSyntax {
        let baseName = expr.baseName
        if let argumentNames = expr.argumentNames {
            throw argumentNames.ext_error(message: "Argument names of \(DeclReferenceExprSyntax.self) unimplemented")
        }

        return """
        IdentifierExpression(identifier: \(stringLiteral(baseName)))
        """
    }

    static func convertPostfix(_ expr: MemberAccessExprSyntax) throws -> ExprSyntax {
        guard let base = expr.base else {
            throw expr.ext_error(message: """
            PostfixExpression does not currently support implicit base postfix member accesses.
            """)
        }

        let baseExprInfo = try managePostfixBase(base)
        let optionalAccess = baseExprInfo.optionalAccess
        var argumentNames: ExprSyntax = "nil"

        if let argNames = expr.declName.argumentNames {
            var names: [ExprSyntax] = []
            for name in argNames.arguments {
                names.append("MemberPostfix.ArgumentName(identifier: \(stringLiteral(name.name)))")
            }
            argumentNames = ExprSyntax(ArrayExprSyntax(expressions: names))
        }

        let memberName = expr.declName.baseName

        return """
        PostfixExpression(
            exp: \(baseExprInfo.base),
            op: MemberPostfix(
                name: \(stringLiteral(memberName)),
                argumentNames: \(argumentNames)
            ).withOptionalAccess(kind: \(optionalAccess.asSwiftASTExpr))
        )
        """
    }

    static func convertPostfix(_ expr: FunctionCallExprSyntax) throws -> ExprSyntax {
        if let trailingClosure = expr.trailingClosure {
            throw trailingClosure.ext_error(message: "Trailing closure parameter conversion not yet implemented.")
        }

        let baseExprInfo = try managePostfixBase(expr.calledExpression)
        let optionalAccess = baseExprInfo.optionalAccess

        let arguments = try labeledExpressions(expr.arguments)

        return """
        PostfixExpression(
            exp: \(baseExprInfo.base),
            op: FunctionCallPostfix(
                arguments: \(ArrayExprSyntax(expressions: try arguments.map(Self.swiftASTFunctionArgument)))
            ).withOptionalAccess(kind: \(optionalAccess.asSwiftASTExpr))
        )
        """
    }

    static func convertPostfix(_ expr: SubscriptCallExprSyntax) throws -> ExprSyntax {
        if let trailingClosure = expr.trailingClosure {
            throw trailingClosure.ext_error(message: "Trailing closure parameter conversion not yet implemented.")
        }

        let baseExprInfo = try managePostfixBase(expr.calledExpression)
        let optionalAccess = baseExprInfo.optionalAccess

        let arguments = try labeledExpressions(expr.arguments)

        return """
        PostfixExpression(
            exp: \(baseExprInfo.base),
            op: SubscriptPostfix(
                arguments: \(ArrayExprSyntax(expressions: try arguments.map(Self.swiftASTFunctionArgument)))
            ).withOptionalAccess(kind: \(optionalAccess.asSwiftASTExpr))
        )
        """
    }

    static func convertPostfix(_ expr: OptionalChainingExprSyntax) throws -> ExprSyntax {
        throw expr.ext_error(message: """
        Multiple nested optional access expressions are not supported by SwiftAST.
        """)
    }

    static func convertPostfix(_ expr: ForceUnwrapExprSyntax) throws -> ExprSyntax {
        throw expr.ext_error(message: """
        Multiple nested optional access expressions are not supported by SwiftAST.
        """)
    }

    static func convertPrefix(_ expr: PrefixOperatorExprSyntax) throws -> ExprSyntax {
        let op = try convertOperator(expr.operator)
        let exp = try self.convertExpression(expr.expression)

        return """
        UnaryExpression(
            op: \(op),
            exp: \(exp)
        )
        """
    }

    static func convertTernary(_ expr: TernaryExprSyntax) throws -> ExprSyntax {
        let condition = try convertExpression(expr.condition)

        let lhs = try convertExpression(expr.thenExpression)
        let rhs = try convertExpression(expr.elseExpression)

        return """
        TernaryExpression(
            exp: \(condition),
            ifTrue: \(lhs),
            ifFalse: \(rhs)
        )
        """
    }

    static func convertTuple(_ expr: TupleExprSyntax) throws -> ExprSyntax {
        var expressions: [ExprSyntax] = []

        for element in expr.elements {
            if let label = element.label, label.tokenKind != .wildcard {
                throw label.ext_error(message: """
                TupleExpression does not currently support tuple labels.
                """)
            }

            expressions.append(try convertExpression(element.expression))
        }

        if expressions.count == 1 {
            return """
            ParensExpression(
                exp: \(expressions[0])
            )
            """
        }

        return """
        TupleExpression(
            elements: \(ArrayExprSyntax(expressions: expressions))
        )
        """
    }

    static func convertTypeCheck(_ expr: IsExprSyntax) throws -> ExprSyntax {
        return """
        TypeCheckExpression(
            exp: \(try convertExpression(expr.expression)),
            type: \(try convertType(expr.type))
        )
        """
    }

    static func convertTryExpression(_ expr: TryExprSyntax) throws -> ExprSyntax {
        let mode: ExprSyntax
        if expr.questionOrExclamationMark?.tokenKind == .postfixQuestionMark {
            mode = "TryExpression.Mode.optional"
        } else if expr.questionOrExclamationMark?.tokenKind == .exclamationMark {
            mode = "TryExpression.Mode.forced"
        } else {
            mode = "TryExpression.Mode.throwable"
        }

        return """
        TryExpression(
            mode: \(mode),
            exp: \(try convertExpression(expr.expression))
        )
        """
    }

    static func convertIf(_ expr: IfExprSyntax) throws -> ExprSyntax {
        let conditionals = try convertConditionals(expr.conditions)
        let body = try convertCompound(expr.body)

        switch expr.elseBody {
        case .codeBlock(let block):
            let elseBody = try convertCompound(block)

            return """
            IfExpression(
                clauses: \(conditionals),
                body: \(body),
                elseBody: .else(\(elseBody))
            )
            """

        case .ifExpr(let elseIf):
            let elseIf = try convertIf(elseIf)

            return """
            IfExpression(
                clauses: \(conditionals),
                body: \(body),
                elseBody: .elseIf(\(elseIf))
            )
            """

        case nil:
            return """
            IfExpression(
                clauses: \(conditionals),
                body: \(body),
                elseBody: nil
            )
            """
        }
    }

    // MARK: - LabeledExprListSyntax

    static func labeledExpressions(_ expr: LabeledExprListSyntax) throws -> [(label: TokenSyntax?, ExprSyntax)] {
        try expr.map(labeledExpression)
    }

    static func labeledExpression(_ expr: LabeledExprSyntax) throws -> (label: TokenSyntax?, ExprSyntax) {
        return (
            label: expr.label,
            try convertExpression(expr.expression)
        )
    }
}

// MARK: - Postfix Expression Helpers

extension SwiftASTConverter {
    static func managePostfixBase(_ expr: ExprSyntax) throws -> PostfixInfo {
        if let expr = expr.as(OptionalChainingExprSyntax.self) {
            return .init(
                base: try convertExpression(expr.expression),
                optionalAccess: .safeUnwrap
            )
        }
        if let expr = expr.as(ForceUnwrapExprSyntax.self) {
            return .init(
                base: try convertExpression(expr.expression),
                optionalAccess: .forceUnwrap
            )
        }

        return .init(
            base: try convertExpression(expr),
            optionalAccess: .none
        )
    }

    static func swiftASTFunctionArgument(_ expr: LabeledExprSyntax) throws -> ExprSyntax {
        let arg = try convertExpression(expr.expression)

        if let label = expr.label {
            return """
            FunctionArgument(
                label: \(stringLiteral(label)),
                expression: \(arg)
            )
            """
        }

        return """
        FunctionArgument(
            label: nil,
            expression: \(arg)
        )
        """
    }

    static func swiftASTFunctionArgument(label: TokenSyntax?, _ exp: ExprSyntax) throws -> ExprSyntax {
        if let label = label {
            return """
            FunctionArgument(
                label: \(stringLiteral(label)),
                expression: \(exp)
            )
            """
        }

        return """
        FunctionArgument(
            label: nil,
            expression: \(exp)
        )
        """
    }

    struct PostfixInfo {
        var base: ExprSyntax
        var optionalAccess: OptionalAccess

        enum OptionalAccess: String {
            case none
            case forceUnwrap
            case safeUnwrap

            var asSwiftASTExpr: ExprSyntax {
                "Postfix.OptionalAccessKind.\(raw: self.rawValue)"
            }
        }
    }
}

// MARK: - SwiftOperator conversion

extension SwiftASTConverter {
    /// Returns an expression that resolves to `SwiftOperator`, constructing the
    /// operator associated with the given `ExprSyntax`.
    ///
    /// Unsupported operator conversions will throw an error.
    static func convertOperator(_ syntax: ExprSyntax) throws -> ExprSyntax {
        let tok = try _SwiftOperator.tryFrom(syntax)
        return tok.asSwiftOperatorExpr
    }

    /// Returns an expression that resolves to `SwiftOperator`, constructing the
    /// operator associated with the given `TokenSyntax`.
    ///
    /// Unsupported operator conversions will throw an error.
    static func convertOperator(_ syntax: TokenSyntax) throws -> ExprSyntax {
        let tok = try _SwiftOperator.tryFrom(syntax)
        return tok.asSwiftOperatorExpr
    }
}
