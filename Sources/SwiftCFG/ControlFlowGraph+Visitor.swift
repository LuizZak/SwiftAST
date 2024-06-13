/// This file contains the main visitor of the bottom-to-top control flow graph
/// creation algorithm, and is abstracted away by ControlFlowGraph+Creation.swift.

import SwiftAST

/// Visitor that produces control flow graphs for syntax trees.
class CFGVisitor: ExpressionVisitor, StatementVisitor {
    typealias ExprResult = CFGVisitResult
    typealias StmtResult = CFGVisitResult

    let options: ControlFlowGraph.GenerationOptions
    var nextId: () -> Int

    init(options: ControlFlowGraph.GenerationOptions, nextId: @escaping () -> Int) {
        self.options = options
        self.nextId = nextId
    }

    // MARK: - Statement

    func visitStatement(_ statement: Statement) -> CFGVisitResult {
        let result = statement.accept(self)

        if statement.isLabelableStatementType, let label = statement.label {
            return result.resolvingJumpsToExit(kind: .break(label: label))
        }

        return result.finalized()
    }

    func visitCompound(_ stmt: CompoundStatement) -> CFGVisitResult {
        enum CompoundEndEntry {
            case `defer`(DeferStatement)
            case endOfScope(CodeScopeNodeType)

            func toGraph(visitor: CFGVisitor) -> CFGVisitResult {
                switch self {
                case .defer(let stmt):
                    return visitor.visitDefer(stmt)
                case .endOfScope(let node):
                    return CFGVisitResult(
                        forNode: ControlFlowGraphEndScopeNode(
                            node: node,
                            scope: node,
                            id: visitor.nextId()
                        )
                    )
                }
            }
        }

        var result = CFGVisitResult(forSyntaxNode: stmt, id: nextId())

        var endEntries: [CompoundEndEntry] = []

        for stmt in stmt.statements {
            let stmtResult = visitStatement(stmt)

            if let stmt = stmt as? DeferStatement {
                endEntries.append(.defer(stmt))
            } else {
                result = result.then(stmtResult)
            }
        }

        endEntries.reverse()

        if options.generateEndScopes {
            endEntries.append(.endOfScope(stmt))
        }

        return
            result
            .then(
                endEntries
                .reduce(CFGVisitResult()) {
                    $0.then($1.toGraph(visitor: self))
                }
            )
            .appendingLazyDefersToJumps {
                endEntries.map {
                    $0.toGraph(visitor: self)
                }
            }
            .finalized()
    }

    func visitConditionalClauses(_ clauses: ConditionalClauses) -> CFGVisitResult {
        let elements = clauses.clauses.map(visitConditionalClauseElement)

        return elements.inSequence()
    }

    func visitConditionalClauseElement(_ clause: ConditionalClauseElement) -> CFGVisitResult {
        // TODO: Conditional clauses can declare definitions within their patterns,
        // TODO: and that should be handled with definition contexts somehow within
        // TODO: the clause elements, or the conditional statements that contain
        // TODO: the clauses
        let node = CFGVisitResult(forSyntaxNode: clause, id: nextId())
        var result = CFGVisitResult()

        if let pattern = clause.pattern {
            result = result.then(
                visitPattern(pattern)
            )
        }

        return result
            .then(visitExpression(clause.expression))
            .then(node)
            .then(CFGVisitResult(branchingToUnresolvedJump: .conditionalClauseFail, id: nextId(), debugLabel: "false"))
            .labelingExits(debugLabel: "true")
    }

    func visitGuard(_ stmt: GuardStatement) -> CFGVisitResult {
        let conditions = stmt.conditionalClauses.accept(self)
        let node = CFGVisitResult(forSyntaxNode: stmt, id: nextId())

        let elseBody = stmt.elseBody.accept(self)

        return node
            .then(conditions)
            .resolvingJumps(kind: .conditionalClauseFail, to: elseBody)
            .finalized()
    }

    func visitIf(_ stmt: IfStatement) -> CFGVisitResult {
        let conditions = stmt.conditionalClauses.accept(self)
        let node = CFGVisitResult(forSyntaxNode: stmt, id: nextId())

        let body = stmt.body.accept(self)
        let elseBody = stmt.elseBody.map(visitElseBody)

        if let elseBody = elseBody {
            return node
                .then(conditions)
                .then(body)
                .resolvingJumps(kind: .conditionalClauseFail, to: elseBody)
                .finalized()
        } else {
            return node
                .then(conditions)
                .then(body)
                .resolvingJumps(kind: .conditionalClauseFail, to: body.exit)
                .finalized()
        }
    }

    func visitElseBody(_ stmt: IfStatement.ElseBody) -> CFGVisitResult {
        switch stmt {
        case .else(let stmts):
            return visitCompound(stmts)
        case .elseIf(let elseIf):
            return visitIf(elseIf)
        }
    }

    func visitWhile(_ stmt: WhileStatement) -> CFGVisitResult {
        let conditions = stmt.conditionalClauses.accept(self)
        let node = CFGVisitResult(forSyntaxNode: stmt, id: nextId())

        let body = stmt.body.accept(self)

        let breakMarker = CFGVisitResult()

        return node
            .then(conditions)
            .then(body)
            .thenLoop(backTo: node.entry, conditionally: false)
            .then(breakMarker)
            .resolvingJumps(kind: .continue(label: nil), to: node.entry)
            .resolvingJumps(kind: .continue(label: stmt.label), to: node.entry)
            .resolvingJumps(kind: .break(label: nil), to: breakMarker.entry)
            .resolvingJumps(kind: .break(label: stmt.label), to: breakMarker.entry)
            .resolvingJumps(kind: .conditionalClauseFail, to: breakMarker.entry)
            .finalized()
    }

    func visitSwitch(_ stmt: SwitchStatement) -> CFGVisitResult {
        let exp = stmt.exp.accept(self)

        let node = CFGVisitResult(forSyntaxNode: stmt, id: nextId())

        let caseClauses = stmt.cases.map(visitSwitchCase)
        let defaultClause = stmt.defaultCase.map(visitSwitchDefaultCase)

        let breakMarker = CFGVisitResult()

        var result = exp
            .then(node)
            .then(breakMarker)

        var totalClauses = caseClauses
        if let defaultClause = defaultClause {
            totalClauses.append(defaultClause)
        }
        for (i, clause) in totalClauses.enumerated() {
            let clauseResult = clause.result

            result = result
                .inserting(clauseResult)
                .branching(from: clauseResult.exit, to: breakMarker.entry)
                .resolvingJumps(kind: .break(label: nil), to: breakMarker.entry)
                .resolvingJumps(kind: .break(label: stmt.label), to: breakMarker.entry)

            if i == 0 {
                result = result.redirectingEntries(
                    for: node.exit,
                    to: clauseResult.entry
                )
            } else {
                result.resolveJumps(
                    caseClauses[i - 1].result.unresolvedJumps(ofKind: .fallthrough),
                    to: clause.fallthroughTarget,
                    debugLabel: "fallthrough"
                )
                result.resolveJumps(
                    caseClauses[i - 1].result.unresolvedJumps(ofKind: .switchCasePatternFail),
                    to: clauseResult.entry,
                    debugLabel: "pattern fail"
                )
            }
        }

        result.removeJumps(kind: .switchCasePatternFail)

        return result.finalized()
    }

    func visitSwitchCase(_ switchCase: SwitchCase) -> SwitchCaseVisitResult {
        print()
        var result =
            CFGVisitResult(forSyntaxNode: switchCase, id: nextId())
            .then(
                switchCase.casePatterns.map(visitSwitchCasePattern)
                .reduce(CFGVisitResult()) {
                    $0.then($1)
                }
            )
            .then(CFGVisitResult(debugLabel: "pattern success"))
            .resolvingJumps(
                kind: .conditionalClauseFail,
                to: CFGVisitResult(
                    forUnresolvedJump: .switchCasePatternFail,
                    id: nextId(),
                    debugLabel: "pattern fail"
                )
            )

        let body = visitStatement(switchCase.body)

        result = result.then(body)

        return .init(
            result: result,
            fallthroughTarget: body.entry
        )
    }

    func visitSwitchCasePattern(_ casePattern: SwitchCase.CasePattern) -> CFGVisitResult {
        let result = visitPattern(casePattern.pattern)
            .then(CFGVisitResult(branchingToUnresolvedJump: .conditionalClauseFail, id: nextId()))

        guard let whereClause = casePattern.whereClause else {
            return result
        }

        let whereClauseResult = visitExpression(whereClause)
            .then(CFGVisitResult(branchingToUnresolvedJump: .conditionalClauseFail, id: nextId()))

        return result
            .then(whereClauseResult)
    }

    func visitSwitchDefaultCase(_ defaultCase: SwitchDefaultCase) -> SwitchCaseVisitResult {
        let body = visitStatement(defaultCase.body)
        let result =
            CFGVisitResult(forSyntaxNode: defaultCase, id: nextId())
            .then(body)

        return .init(
            result: result,
            fallthroughTarget: body.entry
        )
    }

    func visitRepeatWhile(_ stmt: RepeatWhileStatement) -> CFGVisitResult {
        let body = stmt.body.accept(self)
        let exp = stmt.exp.accept(self)
        let head = CFGVisitResult(forSyntaxNode: stmt, id: nextId())
        let breakMark = CFGVisitResult()

        return body
            .then(exp)
            .then(head)
            .then(breakMark)
            .branching(from: head.exit, to: body.entry)
            .resolvingJumps(kind: .continue(label: nil), to: exp.entry)
            .resolvingJumps(kind: .continue(label: stmt.label), to: exp.entry)
            .resolvingJumps(kind: .break(label: nil), to: breakMark.exit)
            .resolvingJumps(kind: .break(label: stmt.label), to: breakMark.exit)
            .finalized()
    }

    func visitFor(_ stmt: ForStatement) -> CFGVisitResult {
        let exp = stmt.exp.accept(self)
        let pattern = visitPattern(stmt.pattern)
        let head = CFGVisitResult(forSyntaxNode: stmt, id: nextId())

        let body = stmt.body.accept(self)

        return exp
            .then(pattern)
            .then(head)
            .then(body)
            .redirectingEntries(for: body.exit, to: pattern.entry)
            .branching(from: head.exit, to: body.exit)
            .resolvingJumps(kind: .continue(label: nil), to: pattern.entry)
            .resolvingJumps(kind: .continue(label: stmt.label), to: pattern.entry)
            .resolvingJumps(kind: .break(label: nil), to: body.exit)
            .resolvingJumps(kind: .break(label: stmt.label), to: body.exit)
            .finalized()
    }

    func visitDo(_ stmt: DoStatement) -> CFGVisitResult {
        let body =
            CFGVisitResult(forSyntaxNode: stmt, id: nextId())
            .then(
                stmt.body.accept(self)
            )

        let endMarker = CFGVisitResult()
        var result = body.then(endMarker)

        var didHandle = false
        for catchBlock in stmt.catchBlocks {
            let blockGraph = visitCatchBlock(catchBlock)

            result = result
                .inserting(blockGraph)
                .branching(from: blockGraph.exit, to: endMarker.entry)

            if !didHandle {
                didHandle = true

                result.resolveJumps(
                    body.unresolvedJumps(ofKind: .throw),
                    to: blockGraph.graph.entry
                )
            }
        }

        return result.finalized()
    }

    func visitCatchBlock(_ block: CatchBlock) -> CFGVisitResult {
        let result = CFGVisitResult(forSyntaxNode: block, id: nextId())

        let pattern = block.pattern.map(visitPattern) ?? CFGVisitResult()
        let body = block.body.accept(self)

        return result.then(pattern).then(body)
    }

    func visitDefer(_ stmt: DeferStatement) -> CFGVisitResult {
        CFGVisitResult(forSyntaxNode: stmt, id: nextId())
            .then(stmt.body.accept(self))
            .resolvingAllJumpsToExit()
    }

    func visitReturn(_ stmt: ReturnStatement) -> CFGVisitResult {
        (stmt.exp?.accept(self) ?? CFGVisitResult()).then (
            CFGVisitResult(forUnresolvedJumpSyntaxNode: stmt, kind: .return, id: nextId())
        ).finalized()
    }

    func visitBreak(_ stmt: BreakStatement) -> CFGVisitResult {
        CFGVisitResult(
            forUnresolvedJumpSyntaxNode: stmt,
            kind: .break(label: stmt.targetLabel),
            id: nextId()
        )
    }

    func visitFallthrough(_ stmt: FallthroughStatement) -> CFGVisitResult {
        CFGVisitResult(
            forUnresolvedJumpSyntaxNode: stmt,
            kind: .fallthrough,
            id: nextId()
        )
    }

    func visitContinue(_ stmt: ContinueStatement) -> CFGVisitResult {
        CFGVisitResult(
            forUnresolvedJumpSyntaxNode: stmt,
            kind: .continue(label: stmt.targetLabel),
            id: nextId()
        )
    }

    func visitExpressions(_ stmt: ExpressionsStatement) -> CFGVisitResult {
        var result = CFGVisitResult(forSyntaxNode: stmt, id: nextId())

        for exp in stmt.expressions {
            var expGraph = visitExpression(exp)
            expGraph.resolveJumpsToExit(kind: .expressionShortCircuit)

            result = result.then(expGraph)
        }

        return result.finalized()
    }

    func visitVariableDeclarations(_ stmt: VariableDeclarationsStatement) -> CFGVisitResult {
        let result = CFGVisitResult(forSyntaxNode: stmt, id: nextId())

        return stmt
            .decl
            .map(visitStatementVariableDeclaration)
            .reduce(result) {
                $0.then($1)
            }.finalized()
    }

    func visitStatementVariableDeclaration(_ decl: StatementVariableDeclaration) -> CFGVisitResult {
        let initialization = decl.initialization.map(visitExpression) ?? CFGVisitResult()

        return initialization
            .then(CFGVisitResult(forSyntaxNode: decl, id: nextId()))
            .finalized()
    }

    func visitLocalFunction(_ stmt: LocalFunctionStatement) -> CFGVisitResult {
        CFGVisitResult(forSyntaxNode: stmt, id: nextId())
    }

    func visitThrow(_ stmt: ThrowStatement) -> CFGVisitResult {
        stmt.exp.accept(self).then (
            CFGVisitResult(forUnresolvedJumpSyntaxNode: stmt, kind: .throw, id: nextId())
        ).finalized()
    }

    func visitUnknown(_ stmt: UnknownStatement) -> CFGVisitResult {
        CFGVisitResult(forSyntaxNode: stmt, id: nextId())
    }

    // MARK: - Expression

    func visitExpression(_ expression: Expression) -> CFGVisitResult {
        var result = expression.accept(self)

        // Merge expressions
        if options.mergeExpressions {
            // Extract the unresolved jumps
            let exitEdges = result.graph.edges(towards: result.exit)
            let hasExit = !exitEdges.isEmpty

            var reduced = CFGVisitResult(forSyntaxNode: expression, id: nextId())

            for jump in result.unresolvedJumps {
                // Extract edge information
                let edgesTo = result.graph.edges(towards: jump.node)
                let edgeLabels = edgesTo.compactMap(\.debugLabel)
                let hasLabels = !edgeLabels.isEmpty

                reduced =
                    reduced.then(
                        CFGVisitResult(
                            branchingToUnresolvedJump: jump.kind,
                            id: nextId(),
                            debugLabel:
                                hasLabels
                                ? edgeLabels.joined(separator: "/")
                                : nil
                        )
                    )
            }

            if !hasExit {
                reduced.removeExitEdges()
            }

            result = reduced
        }

        return result
    }

    func visitAssignment(_ exp: AssignmentExpression) -> CFGVisitResult {
        let suffix = CFGVisitResult()

        var lhs = visitExpression(exp.lhs).inserting(suffix)
        let rhs = visitExpression(exp.rhs).resolvingJumpsToExit(kind: .expressionShortCircuit)

        lhs.resolveJumps(kind: .expressionShortCircuit, to: suffix.graph.exit)

        let node = CFGVisitResult(forSyntaxNode: exp, id: nextId())

        return
            lhs
            .then(rhs)
            .then(node)
            .then(suffix)
            .finalized()
    }

    func visitBinary(_ exp: BinaryExpression) -> CFGVisitResult {
        let lhs = visitExpression(exp.lhs)
        let rhs = visitExpression(exp.rhs)

        let shortCircuit: CFGVisitResult
        switch exp.op {
        case .and, .or, .nullCoalesce:
            shortCircuit = CFGVisitResult(
                branchingToUnresolvedJump: .expressionShortCircuit,
                id: nextId()
            )
        default:
            shortCircuit = CFGVisitResult()
        }

        return lhs
            .then(shortCircuit)
            .then(rhs)
            .resolvingJumpsToExit(kind: .expressionShortCircuit)
            .then(CFGVisitResult(forSyntaxNode: exp, id: nextId()))
            .finalized()
    }

    func visitUnary(_ exp: UnaryExpression) -> CFGVisitResult {
        exp.exp
            .accept(self)
            .resolvingJumpsToExit(kind: .expressionShortCircuit)
            .then(CFGVisitResult(forSyntaxNode: exp, id: nextId()))
            .finalized()
    }

    func visitSizeOf(_ exp: SizeOfExpression) -> CFGVisitResult {
        var result = CFGVisitResult(forSyntaxNode: exp, id: nextId())

        switch exp.value {
        case .expression(let subExp):
            result =
                visitExpression(subExp)
                .resolvingJumpsToExit(kind: .expressionShortCircuit)
                .then(result)
        case .type:
            break
        }

        return result.finalized()
    }

    func visitPrefix(_ exp: PrefixExpression) -> CFGVisitResult {
        exp.exp
            .accept(self)
            .resolvingJumpsToExit(kind: .expressionShortCircuit)
            .then(CFGVisitResult(forSyntaxNode: exp, id: nextId()))
            .finalized()
    }

    func visitPostfix(_ exp: PostfixExpression) -> CFGVisitResult {
        let operand: CFGVisitResult = visitExpression(exp.exp)

        var opExp = CFGVisitResult()
        for subExp in exp.op.subExpressions {
            let param = visitExpression(subExp)

            opExp = opExp.then(
                param.resolvingJumpsToExit(kind: .expressionShortCircuit)
            )
        }

        let shortCircuit: CFGVisitResult
        switch exp.op.optionalAccessKind {
        case .none, .forceUnwrap:
            shortCircuit = CFGVisitResult()
        case .safeUnwrap:
            shortCircuit = CFGVisitResult(
                branchingToUnresolvedJump: .expressionShortCircuit,
                id: nextId()
            )
        }

        return
            operand
            .then(opExp)
            .then(
                CFGVisitResult(forSyntaxNode: exp, id: nextId())
            )
            .then(shortCircuit)
            .finalized()
    }

    func visitConstant(_ exp: ConstantExpression) -> CFGVisitResult {
        CFGVisitResult(forSyntaxNode: exp, id: nextId())
    }

    func visitParens(_ exp: ParensExpression) -> CFGVisitResult {
        exp.exp
            .accept(self)
            .resolvingJumpsToExit(kind: .expressionShortCircuit)
            .then(CFGVisitResult(forSyntaxNode: exp, id: nextId()))
            .finalized()
    }

    func visitIdentifier(_ exp: IdentifierExpression) -> CFGVisitResult {
        CFGVisitResult(forSyntaxNode: exp, id: nextId())
    }

    func visitCast(_ exp: CastExpression) -> CFGVisitResult {
        visitExpression(exp.exp)
            .resolvingJumpsToExit(kind: .expressionShortCircuit)
            .then(CFGVisitResult(forSyntaxNode: exp, id: nextId()))
            .finalized()
    }

    func visitTypeCheck(_ exp: TypeCheckExpression) -> CFGVisitResult {
        visitExpression(exp.exp)
            .resolvingJumpsToExit(kind: .expressionShortCircuit)
            .then(CFGVisitResult(forSyntaxNode: exp, id: nextId()))
            .finalized()
    }

    func visitArray(_ exp: ArrayLiteralExpression) -> CFGVisitResult {
        var result = CFGVisitResult()

        for item in exp.items {
            let item = visitExpression(item)

            result = result.then(
                item.resolvingJumpsToExit(kind: .expressionShortCircuit)
            )
        }

        return result
            .then(CFGVisitResult(forSyntaxNode: exp, id: nextId()))
            .finalized()
    }

    func visitDictionary(_ exp: DictionaryLiteralExpression) -> CFGVisitResult {
        var result = CFGVisitResult()

        for pair in exp.pairs {
            let key =
                visitExpression(pair.key)
                .resolvingJumpsToExit(kind: .expressionShortCircuit)

            let value =
                visitExpression(pair.value)
                .resolvingJumpsToExit(kind: .expressionShortCircuit)

            result = result.then(
                key.then(value)
            )
        }

        return result
            .then(CFGVisitResult(forSyntaxNode: exp, id: nextId()))
            .finalized()
    }

    func visitBlock(_ exp: BlockLiteralExpression) -> CFGVisitResult {
        CFGVisitResult(forSyntaxNode: exp, id: nextId())
    }

    func visitTernary(_ exp: TernaryExpression) -> CFGVisitResult {
        let predicate =
            exp.exp
            .accept(self)
            .resolvingJumpsToExit(kind: .expressionShortCircuit)

        let lhs =
            exp.ifTrue
            .accept(self)
            .resolvingJumpsToExit(kind: .expressionShortCircuit)

        let rhs =
            exp.ifFalse
            .accept(self)
            .resolvingJumpsToExit(kind: .expressionShortCircuit)

        let node = CFGVisitResult(forSyntaxNode: exp, id: nextId())

        return predicate
            .then(node)
            .then(
                inParallel(lhs, rhs)
            )
            .finalized()
    }

    func visitTuple(_ exp: TupleExpression) -> CFGVisitResult {
        var result = CFGVisitResult()

        for item in exp.elements {
            let item = visitExpression(item)

            result = result.then(
                item.resolvingJumpsToExit(kind: .expressionShortCircuit)
            )
        }

        return result
            .then(CFGVisitResult(forSyntaxNode: exp, id: nextId()))
            .finalized()
    }

    func visitSelector(_ exp: SelectorExpression) -> CFGVisitResult {
        CFGVisitResult(forSyntaxNode: exp, id: nextId())
    }

    func visitTry(_ exp: TryExpression) -> CFGVisitResult {
        let result =
            visitExpression(exp.exp)
            .resolvingJumpsToExit(kind: .expressionShortCircuit)

        let node: CFGVisitResult
        switch exp.mode {
        case .throwable:
            node = CFGVisitResult(
                withBranchingSyntaxNode: exp,
                toUnresolvedJump: .throw,
                id: nextId(),
                debugLabel: "throws"
            )

        case .optional, .forced:
            node = .init(forSyntaxNode: exp, id: nextId())
        }

        return result.then(node)
    }

    func visitUnknown(_ exp: UnknownExpression) -> CFGVisitResult {
        CFGVisitResult(forSyntaxNode: exp, id: nextId())
    }

    func visitPattern(_ pattern: Pattern) -> CFGVisitResult {
        pattern
            .subExpressions
            .map(visitExpression)
            .reduce(CFGVisitResult()) {
                $0.then($1)
            }
            .finalized()
    }

    struct SwitchCaseVisitResult {
        var result: CFGVisitResult
        var fallthroughTarget: ControlFlowGraphNode
    }
}

/// Returns the given list of results, joined by a single entry and exit node,
/// running in 'parallel'.
private func inParallel(_ results: CFGVisitResult...) -> CFGVisitResult {
    let entry = ControlFlowGraphEntryNode(node: MarkerSyntaxNode())
    let exit = ControlFlowGraphExitNode(node: MarkerSyntaxNode())

    var result = CFGVisitResult()
    result.graph.addNode(entry)
    result.graph.addNode(exit)

    for item in results {
        result = result
            .inserting(item)

        result.graph.addEdge(
            from: entry,
            to: item.graph.entry
        )
        result.graph.addEdge(
            from: item.graph.exit,
            to: exit
        )
    }

    result.graph.entry = entry
    result.graph.exit = exit

    return result
}

private extension Sequence where Element == CFGVisitResult {
    /// Returns the result of concatenating each result within this sequence to
    /// the next by connecting their exits, in a `r1.then(r2).then(r3)` fashion.
    ///
    /// If this sequence is empty, an empty result is returned.
    func inSequence() -> CFGVisitResult {
        var result = CFGVisitResult()
        for next in self {
            result = result.then(next)
        }
        return result
    }
}
