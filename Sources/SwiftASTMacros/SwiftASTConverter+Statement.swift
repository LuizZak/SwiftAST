import SwiftSyntax

// MARK: - Statement conversion

extension SwiftASTConverter {
    static func convertStatement(_ stmt: StmtSyntax) throws -> ExprSyntax {
        if let stmt = stmt.as(BreakStmtSyntax.self) {
            return try convertBreak(stmt)
        }
        if let stmt = stmt.as(ContinueStmtSyntax.self) {
            return try convertContinue(stmt)
        }
        if let stmt = stmt.as(DeferStmtSyntax.self) {
            return try convertDefer(stmt)
        }
        if let stmt = stmt.as(DoStmtSyntax.self) {
            return try convertDo(stmt)
        }
        if let stmt = stmt.as(RepeatStmtSyntax.self) {
            return try convertRepeatWhile(stmt)
        }
        if let stmt = stmt.as(ExpressionStmtSyntax.self) {
            // If expression
            if let stmt = stmt.expression.as(IfExprSyntax.self) {
                return try convertIf(stmt)
            }
            // Switch expression
            if let stmt = stmt.expression.as(SwitchExprSyntax.self) {
                return try convertSwitch(stmt)
            }

            return try convertExpressions(stmt)
        }
        if let stmt = stmt.as(FallThroughStmtSyntax.self) {
            return try convertFallthrough(stmt)
        }
        if let stmt = stmt.as(GuardStmtSyntax.self) {
            return try convertGuard(stmt)
        }
        if let stmt = stmt.as(ForStmtSyntax.self) {
            return try convertFor(stmt)
        }
        if let stmt = stmt.as(ReturnStmtSyntax.self) {
            return try convertReturn(stmt)
        }
        if let stmt = stmt.as(ThrowStmtSyntax.self) {
            return try convertThrow(stmt)
        }
        if let stmt = stmt.as(WhileStmtSyntax.self) {
            return try convertWhile(stmt)
        }

        throw stmt.ext_error(message: """
        Unsupported statement kind \(stmt.kind)
        """)
    }

    static func convertCompound(_ stmt: CodeBlockSyntax) throws -> ExprSyntax {
        return try convertCompound(stmt.statements)
    }

    static func convertCompound(_ stmt: CodeBlockItemListSyntax) throws -> ExprSyntax {
        let items = try convertStatements(stmt)

        return """
        CompoundStatement(statements: \(ArrayExprSyntax(expressions: items)))
        """
    }

    static func convertStatements(_ stmt: CodeBlockItemListSyntax) throws -> [ExprSyntax] {
        try stmt.map(convertStatement)
    }

    static func convertStatement(_ blockItem: CodeBlockItemSyntax) throws -> ExprSyntax {
        switch blockItem.item {
        case .stmt(let stmt):
            return try convertStatement(stmt)

        case .expr(let expr):
            let exp = try convertExpression(expr)

            return """
            ExpressionsStatement(
                expressions: [\(exp)]
            )
            """

        case .decl(let decl):
            if let funcDecl = decl.as(FunctionDeclSyntax.self) {
                return try convertLocalFunctionStatement(funcDecl)
            }
            if let varDecl = decl.as(VariableDeclSyntax.self) {
                return try convertVariableDeclarations(varDecl)
            }

            throw decl.ext_error(message: """
            Unsupported SwiftAST.Statement declaration kind as member of statements list.
            """)
        }
    }

    static func convertBreak(_ stmt: BreakStmtSyntax) throws -> ExprSyntax {
        if let label = stmt.label {
            return "BreakStatement(targetLabel: \(stringLiteral(label)))"
        } else {
            return "BreakStatement(targetLabel: nil)"
        }
    }

    static func convertContinue(_ stmt: ContinueStmtSyntax) throws -> ExprSyntax {
        if let label = stmt.label {
            return "ContinueStatement(targetLabel: \(stringLiteral(label)))"
        } else {
            return "ContinueStatement(targetLabel: nil)"
        }
    }

    static func convertDefer(_ stmt: DeferStmtSyntax) throws -> ExprSyntax {
        return """
        DeferStatement(
            body: \(try convertCompound(stmt.body))
        )
        """
    }

    static func convertDo(_ stmt: DoStmtSyntax) throws -> ExprSyntax {
        let clauses = try stmt.catchClauses.map(convertCatchBlock(_:))

        return """
        DoStatement(
            body: \(try convertCompound(stmt.body)),
            catchBlocks: \(ArrayExprSyntax(expressions: clauses))
        )
        """
    }

    static func convertRepeatWhile(_ stmt: RepeatStmtSyntax) throws -> ExprSyntax {
        return """
        RepeatWhileStatement(
            expression: \(try convertExpression(stmt.condition)),
            body: \(try convertCompound(stmt.body))
        )
        """
    }

    static func convertExpressions(_ stmt: ExpressionStmtSyntax) throws -> ExprSyntax {
        return """
        ExpressionStatement(
            expressions: [\(try convertExpression(stmt.expression))]
        )
        """
    }

    static func convertFallthrough(_ stmt: FallThroughStmtSyntax) throws -> ExprSyntax {
        return """
        FallthroughStatement()
        """
    }

    static func convertIf(_ stmt: IfExprSyntax) throws -> ExprSyntax {
        let conditionals = try convertConditionals(stmt.conditions)
        let body = try convertCompound(stmt.body)

        switch stmt.elseBody {
        case .codeBlock(let block):
            let elseBody = try convertCompound(block)

            return """
            IfStatement(
                clauses: \(conditionals),
                body: \(body),
                elseBody: .else(\(elseBody))
            )
            """

        case .ifExpr(let elseIf):
            let elseIf = try convertIf(elseIf)

            return """
            IfStatement(
                clauses: \(conditionals),
                body: \(body),
                elseBody: .elseIf(\(elseIf))
            )
            """

        case nil:
            return """
            IfStatement(
                clauses: \(conditionals),
                body: \(body),
                elseBody: nil
            )
            """
        }
    }

    static func convertGuard(_ stmt: GuardStmtSyntax) throws -> ExprSyntax {
        let conditionals = try convertConditionals(stmt.conditions)
        let body = try convertCompound(stmt.body)

        return """
        GuardStatement(
            clauses: \(conditionals),
            elseBody: \(body)
        )
        """
    }

    static func convertFor(_ stmt: ForStmtSyntax) throws -> ExprSyntax {
        if let caseKeyword = stmt.caseKeyword {
            throw caseKeyword.ext_error(message: """
            ForStatement does not support 'case' iterator patterns.
            """)
        }
        if let tryKeyword = stmt.tryKeyword {
            throw tryKeyword.ext_error(message: """
            ForStatement does not support 'try' iterator patterns.
            """)
        }
        if let awaitKeyword = stmt.awaitKeyword {
            throw awaitKeyword.ext_error(message: """
            ForStatement does not support 'await' iterator patterns.
            """)
        }
        if let whereClause = stmt.whereClause {
            throw whereClause.ext_error(message: """
            ForStatement does not support 'where' clauses.
            """)
        }
        if let type = stmt.typeAnnotation {
            throw type.ext_error(message: """
            ForStatement does not support type annotations.
            """)
        }

        let pattern = try convertPattern(stmt.pattern)
        let exp = try convertExpression(stmt.sequence)
        let body = try convertCompound(stmt.body)

        return """
        ForStatement(
            pattern: \(pattern),
            exp: \(exp),
            body: \(body)
        )
        """
    }

    static func convertLocalFunctionStatement(_ stmt: FunctionDeclSyntax) throws -> ExprSyntax {
        let localFunction = try convertAsLocalFunction(stmt)

        return """
        LocalFunctionStatement(
            function: \(localFunction)
        )
        """
    }

    static func convertReturn(_ stmt: ReturnStmtSyntax) throws -> ExprSyntax {
        if let expression = stmt.expression {
            return "ReturnStatement(exp: \(try convertExpression(expression)))"
        }

        return "ReturnStatement()"
    }

    static func convertSwitch(_ stmt: SwitchExprSyntax) throws -> ExprSyntax {
        let expr = try convertExpression(stmt.subject)

        let result = try convertSwitchCaseList(stmt.cases)
        let cases = ArrayExprSyntax(expressions: result.cases)

        if let defaultCase = result.defaultCase {
            return """
            SwitchStatement(
                exp: \(expr),
                cases: \(cases),
                defaultCase: SwitchDefaultCase(
                    statements: \(ArrayExprSyntax(expressions: defaultCase))
                )
            )
            """
        }

        return """
        SwitchStatement(
            exp: \(expr),
            cases: \(cases),
            defaultCase: nil
        )
        """
    }

    static func convertThrow(_ stmt: ThrowStmtSyntax) throws -> ExprSyntax {
        return """
        ThrowStatement(exp: \(try convertExpression(stmt.expression)))
        """
    }

    static func convertVariableDeclarations(_ stmt: VariableDeclSyntax) throws -> ExprSyntax {
        if let attribute = stmt.attributes.first {
            throw attribute.ext_error(message: """
            VariableDeclarationsStatement does not support attributes.
            """)
        }

        let modifiers = stmt.modifiers
        let bindingSpecifier = stmt.bindingSpecifier

        var decls: [ExprSyntax] = []
        for binding in stmt.bindings {
            let decl = try convertStatementVariableDeclaration(
                modifiers: modifiers,
                bindingSpecifier: bindingSpecifier,
                binding: binding
            )

            decls.append(decl)
        }

        return """
        VariableDeclarationsStatement(
            decl: \(ArrayExprSyntax(expressions: decls))
        )
        """
    }

    static func convertWhile(_ stmt: WhileStmtSyntax) throws -> ExprSyntax {
        let conditionals = try convertConditionals(stmt.conditions)
        let body = try convertCompound(stmt.body)

        return """
        WhileStatement(
            clauses: \(conditionals),
            body: \(body)
        )
        """
    }
}

// MARK: Conditional Clause conversion

extension SwiftASTConverter {
    /// Returns an expression that resolves to `ConditionalClauses`.
    static func convertConditionals(_ list: ConditionElementListSyntax) throws -> ExprSyntax {
        let conditionals = try list.map(convertConditional)

        return """
        ConditionalClauses(
            clauses: \(ArrayExprSyntax(expressions: conditionals))
        )
        """
    }

    /// Returns an expression that resolves to `ConditionalClauseElement`.
    static func convertConditional(_ syntax: ConditionElementSyntax) throws -> ExprSyntax {
        switch syntax.condition {
        case .expression(let inner):
            let expression = try convertExpression(inner)

            return """
            ConditionalClauseElement(
                expression: \(expression)
            )
            """

        case .matchingPattern(let inner):
            let pattern = try convertPattern(inner.pattern)
            let expression = try convertExpression(inner.initializer.value)

            return """
            ConditionalClauseElement(
                pattern: \(pattern),
                expression: \(expression)
            )
            """

        case .availability(_):
            throw syntax.ext_error(message: """
            ConditionalClauseElement does not support #available conditionals.
            """)

        case .optionalBinding(let inner):
            guard let value = inner.initializer?.value else {
                throw inner.ext_error(message: """
                ConditionalClauseElement does not support implicit optional unwraps.
                """)
            }

            let pattern = try convertPattern(inner.pattern)
            let expression = try convertExpression(value)

            return """
            ConditionalClauseElement(
                pattern: \(pattern),
                expression: \(expression)
            )
            """
        }
    }
}

// MARK: Pattern conversion

extension SwiftASTConverter {
    static func convertPattern(_ pattern: PatternSyntax) throws -> ExprSyntax {
        if let value = pattern.as(ExpressionPatternSyntax.self) {
            return try convertPattern(value)
        }
        if let value = pattern.as(IdentifierPatternSyntax.self) {
            return try convertPattern(value)
        }
        if let value = pattern.as(TuplePatternSyntax.self) {
            return try convertPattern(value)
        }
        if let value = pattern.as(WildcardPatternSyntax.self) {
            return try convertPattern(value)
        }
        if let value = pattern.as(ValueBindingPatternSyntax.self) {
            return try convertPattern(value)
        }

        throw pattern.ext_error(message: "Unsupported pattern kind \(pattern.kind)")
    }

    static func convertPattern(_ pattern: ExpressionPatternSyntax) throws -> ExprSyntax {
        return """
        Pattern.expression(\(try convertExpression(pattern.expression)))
        """
    }

    static func convertPattern(_ pattern: IdentifierPatternSyntax) throws -> ExprSyntax {
        return "Pattern.identifier(\(stringLiteral(pattern.identifier)))"
    }

    static func convertPattern(_ pattern: TuplePatternSyntax) throws -> ExprSyntax {
        var elements: [ExprSyntax] = []

        for element in pattern.elements {
            if element.label != nil {
                throw element.ext_error(message: "Tuple patterns don't support labels")
            }

            elements.append(try convertPattern(element.pattern))
        }

        return """
        Pattern.tuple(\(ArrayExprSyntax(expressions: elements)))
        """
    }

    static func convertPattern(_ pattern: ValueBindingPatternSyntax) throws -> ExprSyntax {
        switch pattern.bindingSpecifier.tokenKind {
        case .keyword(.var):
            return """
            Pattern.valueBindingPattern(constant: false, \(try convertPattern(pattern.pattern)))
            """

        case .keyword(.let):
            return """
            Pattern.valueBindingPattern(constant: true, \(try convertPattern(pattern.pattern)))
            """

        default:
            throw pattern.bindingSpecifier.ext_error(message: """
            Unrecognized binding specifier in pattern
            """)
        }
    }

    static func convertPattern(_ pattern: WildcardPatternSyntax) throws -> ExprSyntax {
        return "Pattern.wildcard"
    }
}

// MARK: - Do statement helpers

extension SwiftASTConverter {
    static func convertCatchBlock(_ catchBlock: CatchClauseSyntax) throws -> ExprSyntax {
        let pattern = try convertCatchItems(catchBlock.catchItems)
        let body = try convertCompound(catchBlock.body)

        return """
        CatchBlock(
            pattern: \(pattern),
            body: \(body)
        )
        """
    }

    static func convertCatchItems(_ catchItems: CatchItemListSyntax) throws -> ExprSyntax {
        if catchItems.count > 1 {
            throw catchItems.ext_error(message: """
            CatchBlock does not support catch blocks with more than one pattern.
            """)
        }

        guard let catchItem = catchItems.first else {
            return "nil"
        }
        guard let catchPattern = catchItem.pattern else {
            throw catchItem.ext_error(message: """
            Expected pattern in catch item.
            """)
        }

        if let whereClause = catchItem.whereClause {
            throw whereClause.ext_error(message: """
            CatchBlock does not support catch blocks with where clauses.
            """)
        }

        return try convertPattern(catchPattern)
    }
}

// MARK: - Switch statement helpers

extension SwiftASTConverter {
    static func convertSwitchCaseList(_ stmt: SwitchCaseListSyntax) throws -> SwitchCaseListResult {
        var cases: [ExprSyntax] = []
        var defaultCase: [ExprSyntax]?

        for element in stmt {
            switch element {
            case .ifConfigDecl(let ifConfigDecl):
                throw ifConfigDecl.ext_error(message: """
                SwitchStatement does not support interleaved '#if' statements within cases.
                """)

            case .switchCase(let switchCase):
                let stmts = try convertStatements(switchCase.statements)

                switch switchCase.label {
                case .case(let label):
                    cases.append(try convertSwitchCase(label, stmts))

                case .default(let label):
                    guard defaultCase == nil else {
                        throw label.ext_error(message: """
                        Unexpected two default cases in switch statement
                        """)
                    }

                    defaultCase = stmts
                }
            }
        }

        return SwitchCaseListResult(
            cases: cases,
            defaultCase: defaultCase
        )
    }

    static func convertSwitchCase(
        _ label: SwitchCaseLabelSyntax,
        _ stmts: [ExprSyntax]
    ) throws -> ExprSyntax {

        let casePatterns = try label.caseItems.map(convertSwitchCasePattern(_:))

        return """
        SwitchCase(
            casePatterns: \(ArrayExprSyntax(expressions: casePatterns)),
            body: CompoundStatement(statements: \(ArrayExprSyntax(expressions: stmts)))
        )
        """
    }

    static func convertSwitchCasePattern(_ casePattern: SwitchCaseItemSyntax) throws -> ExprSyntax {
        let pattern = try convertPattern(casePattern.pattern)
        let whereClause = try casePattern.whereClause.map(convertWhereClause)

        if let whereClause {
            return """
            SwitchCase.CasePattern(
                pattern: \(pattern),
                whereClause: \(whereClause)
            )
            """
        }

        return """
        SwitchCase.CasePattern(
            pattern: \(pattern)
        )
        """
    }

    static func convertWhereClause(_ whereClause: WhereClauseSyntax) throws -> ExprSyntax {
        return try convertExpression(whereClause.condition)
    }

    struct SwitchCaseListResult {
        var cases: [ExprSyntax]
        var defaultCase: [ExprSyntax]?
    }
}

// MARK: - LocalFunction conversion

extension SwiftASTConverter {
    /// Returns an expression that resolves to `LocalFunction`.
    static func convertAsLocalFunction(_ decl: FunctionDeclSyntax) throws -> ExprSyntax {
        if let attribute = decl.attributes.first {
            throw attribute.ext_error(message: """
            LocalFunctionStatement does not support attributes.
            """)
        }
        // TODO: Support mutating/static traits, which are already supported by FunctionSignature.Traits
        if let modifier = decl.modifiers.first {
            throw modifier.ext_error(message: """
            LocalFunctionStatement does not support modifiers.
            """)
        }
        if let genericParameterClause = decl.genericParameterClause {
            throw genericParameterClause.ext_error(message: """
            LocalFunctionStatement does not support generic parameters or generic where clauses.
            """)
        }
        if let genericWhereClause = decl.genericWhereClause {
            throw genericWhereClause.ext_error(message: """
            LocalFunctionStatement does not support generic parameters or generic where clauses.
            """)
        }
        guard let body = decl.body else {
            throw decl.ext_error(message: """
            LocalFunctionStatement requires a body.
            """)
        }

        let signature = try convertSignature(
            name: ExprSyntax(stringLiteral(decl.name)),
            decl.signature
        )
        let compoundStatement = try convertCompound(body)

        return """
        LocalFunction(
            signature: \(signature),
            body: \(compoundStatement)
        )
        """
    }
}

// MARK: - Signature conversion

extension SwiftASTConverter {
    /// Returns an expression that resolves to `FunctionSignature`.
    static func convertSignature(
        name: ExprSyntax,
        _ signature: FunctionSignatureSyntax
    ) throws -> ExprSyntax {

        var returnType: ExprSyntax = swiftTypeVoid
        if let returnClause = signature.returnClause {
            returnType = try convertType(returnClause.type)
        }

        let parameters = try signature.parameterClause.parameters.map(convertParameterSignature(_:))
        let effectsSpecifier = try convertTraits(signature.effectSpecifiers)

        return """
        FunctionSignature(
            name: \(name),
            parameters: \(ArrayExprSyntax(expressions: parameters)),
            returnType: \(returnType),
            traits: \(effectsSpecifier)
        )
        """
    }

    /// Returns an expression that resolves to `ParameterSignature`
    static func convertParameterSignature(
        _ parameter: FunctionParameterSyntax
    ) throws -> ExprSyntax {
        if let attributes = parameter.attributes.first {
            throw attributes.ext_error(message: """
            ParameterSignature does not support attributes.
            """)
        }
        if let defaultValue = parameter.defaultValue {
            throw defaultValue.ext_error(message: """
            ParameterSignature does not support default values.
            """)
        }

        var label: ExprSyntax?
        var name: ExprSyntax
        let type = try convertType(parameter.type)
        let isVariadic: ExprSyntax

        //                     label    |    name
        // no second name  | firstName  | firstName
        //                 |            |
        // w/ second name  | firstName  | secondName
        //                 |            |
        // w/ second name  |    nil     | secondName
        //  (first name _) |            |
        let firstName = parameter.firstName
        if let secondName = parameter.secondName {
            name = ExprSyntax(stringLiteral(secondName))

            if firstName.tokenKind == .wildcard {
                label = "nil"
            } else {
                label = ExprSyntax(stringLiteral(firstName))
            }
        } else {
            label = ExprSyntax(stringLiteral(firstName))
            name = ExprSyntax(stringLiteral(firstName))
        }

        if parameter.ellipsis != nil {
            isVariadic = "true"
        } else {
            isVariadic = "false"
        }

        return """
        ParameterSignature(
            label: \(label),
            name: \(name),
            type: \(type),
            isVariadic: \(isVariadic),
            hasDefaultValue: false
        )
        """
    }

    /// Returns an expression that resolves to `FunctionSignature.Traits`.
    static func convertTraits(_ effectsSpecifier: EffectSpecifiersSyntax?) throws -> ExprSyntax {
        guard let effectsSpecifier else {
            return "FunctionSignature.Traits()"
        }

        if let asyncSpecifier = effectsSpecifier.asyncSpecifier {
            throw asyncSpecifier.ext_error(message: """
            FunctionSignature does not support async trait.
            """)
        }

        if let throwsSpecifier = effectsSpecifier.throwsSpecifier {
            guard throwsSpecifier.tokenKind != .keyword(.rethrows) else {
                throw throwsSpecifier.ext_error(message: """
                FunctionSignature does not support rethrows trait.
                """)
            }

            return "FunctionSignature.Traits.throwing"
        }

        return "FunctionSignature.Traits()"
    }
}

// MARK: - Variable declaration helpers

extension SwiftASTConverter {
    /// Returns an expression that resolves to `StatementVariableDeclaration`.
    static func convertStatementVariableDeclaration(
        modifiers: DeclModifierListSyntax,
        bindingSpecifier: TokenSyntax,
        binding: PatternBindingSyntax
    ) throws -> ExprSyntax {

        guard let typeAnnotation = binding.typeAnnotation else {
            throw binding.ext_error(message: """
            StatementVariableDeclaration requires explicit type annotations.
            """)
        }
        guard let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            throw binding.pattern.ext_error(message: """
            VariableDeclarationsStatement does not support non-identifier bindings.
            """)
        }

        let identifier = stringLiteral(identifierPattern.identifier)
        let storage = try convertValueStorage(
            modifiers: modifiers,
            bindingSpecifier: bindingSpecifier,
            type: typeAnnotation.type
        )

        let initialization: ExprSyntax
        if let initializer = binding.initializer?.value {
            initialization = try convertExpression(initializer)
        } else {
            initialization = "nil"
        }

        return """
        StatementVariableDeclaration(
            identifier: \(identifier),
            storage: \(storage),
            initialization: \(initialization)
        )
        """
    }

    /// Returns an expression that resolves to `ValueStorage`.
    static func convertValueStorage(
        modifiers: DeclModifierListSyntax,
        bindingSpecifier: TokenSyntax,
        type: TypeSyntax
    ) throws -> ExprSyntax {

        var ownership: ExprSyntax = "Ownership.strong"
        for modifier in modifiers {
            ownership = try convertOwnershipModifier(modifier)
        }

        let type = try convertType(type)
        let isConstant = try convertIsConstant(bindingSpecifier: bindingSpecifier)

        return """
        ValueStorage(
            type: \(type),
            ownership: \(ownership),
            isConstant: \(isConstant)
        )
        """
    }

    /// Returns an expression that resolves to `Bool`, or whether the given
    /// binding specifier is a constant (`let`) or not (`var`).
    static func convertIsConstant(bindingSpecifier specifier: TokenSyntax) throws -> ExprSyntax {
        let desc = specifier.trimmed.description

        switch desc {
        case "let":
            return "true"
        case "var":
            return "false"
        default:
            throw specifier.ext_error(message: """
            Unsupported binding specifier.
            """)
        }
    }

    /// Returns an expression that resolves to `Ownership`.
    static func convertOwnershipModifier(_ modifier: DeclModifierSyntax) throws -> ExprSyntax {
        let desc = modifier.trimmed.description

        switch desc {
        case "strong":
            return "Ownership.strong"
        case "weak":
            return "Ownership.weak"
        case "unowned(safe)":
            return "Ownership.unownedSafe"
        case "unowned(unsafe)":
            return "Ownership.unownedUnsafe"
        default:
            throw modifier.ext_error(message: """
            Unsupported declaration modifier.
            """)
        }
    }
}
