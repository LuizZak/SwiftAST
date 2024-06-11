import SwiftAST

public struct CFGVisitResult {
    public var graph: ControlFlowGraph
    public var unresolvedJumps: [UnresolvedJump]

    /// Gets the entry node for this graph result.
    public var entry: ControlFlowGraphEntryNode {
        graph.entry
    }

    /// Gets the exit node for this graph result.
    public var exit: ControlFlowGraphExitNode {
        graph.exit
    }

    /// Initializes a graph from a syntax node, `entry -> syntaxNode -> exit`.
    init(forSyntaxNode syntaxNode: SyntaxNode, id: Int) {
        self.init(forNode: ControlFlowGraphNode(node: syntaxNode, id: id))
    }

    /// Initializes a graph from a graph node, `entry -> node -> exit`.
    init(forNode node: ControlFlowGraphNode) {
        self.init()

        graph.prepend(node, before: exit)
    }

    /// Initializes a graph from a syntax node that points to an unresolved jump,
    /// which branches off from the main exit, which remains unconnected.
    ///
    /// `entry -> syntaxNode -> jump X-> exit`.
    init(
        forUnresolvedJumpSyntaxNode syntaxNode: SyntaxNode,
        kind: UnresolvedJump.Kind,
        id: Int
    ) {

        let node = ControlFlowGraphNode(node: syntaxNode, id: id)

        self.init()

        let jump = UnresolvedJump(
            node: ControlFlowGraphUnresolvedJumpNode(
                node: MarkerSyntaxNode(),
                id: id,
                debugLabel: kind.description
            ),
            kind: kind
        )

        graph.prepend(node, before: exit)
        graph.removeEdge(from: node, to: exit)
        graph.addNode(jump.node)
        graph.addEdge(from: node, to: jump.node)

        unresolvedJumps = [jump]
    }

    /// Initializes a graph where the entry points to an unresolved jump, with no
    /// connection to the exit.
    ///
    /// `entry -> jump X-> exit`.
    init(forUnresolvedJump kind: UnresolvedJump.Kind, id: Int) {
        self.init()

        let jump = UnresolvedJump(
            node: ControlFlowGraphUnresolvedJumpNode(
                node: MarkerSyntaxNode(),
                id: id,
                debugLabel: kind.description
            ),
            kind: kind
        )

        graph.prepend(jump.node, before: exit)
        graph.removeEdge(from: jump.node, to: exit)

        unresolvedJumps = [jump]
    }

    /// Initializes a graph from a syntax node that points to both the exit
    /// and to an unresolved jump node.
    ///
    /// ```
    /// entry -> syntaxNode --> exit
    ///                     \-> jump
    /// ```
    init(
        withBranchingSyntaxNode syntaxNode: SyntaxNode,
        toUnresolvedJump kind: UnresolvedJump.Kind,
        id: Int,
        debugLabel: String? = nil
    ) {

        let node = ControlFlowGraphNode(node: syntaxNode, id: id)

        self.init()

        let jump = UnresolvedJump(
            node: ControlFlowGraphUnresolvedJumpNode(
                node: MarkerSyntaxNode(),
                id: id,
                debugLabel: kind.description
            ),
            kind: kind
        )

        graph.prepend(node, before: exit)
        graph.addNode(jump.node)
        let edge = graph.addEdge(from: node, to: jump.node)
        edge.debugLabel = debugLabel

        unresolvedJumps = [jump]
    }

    /// Initializes a graph where the entry node points to both the exit and to
    /// an unresolved jump node.
    ///
    /// ```
    /// entry --> exit
    ///       \-> jump
    /// ```
    init(
        branchingToUnresolvedJump kind: UnresolvedJump.Kind,
        id: Int,
        debugLabel: String? = nil
    ) {
        self.init()

        let jump = UnresolvedJump(
            node: ControlFlowGraphUnresolvedJumpNode(
                node: MarkerSyntaxNode(),
                id: id,
                debugLabel: kind.description
            ),
            kind: kind
        )

        graph.addNode(jump.node)
        let edge = graph.addEdge(from: graph.entry, to: jump.node)
        edge.debugLabel = debugLabel

        unresolvedJumps = [jump]
    }

    /// Initializes an empty CFG visit result.
    init() {
        graph = ControlFlowGraph(
            entry: ControlFlowGraphEntryNode(node: MarkerSyntaxNode()),
            exit: ControlFlowGraphExitNode(node: MarkerSyntaxNode())
        )
        unresolvedJumps = []

        graph.addEdge(from: entry, to: exit)
    }

    /// Returns a list of unresolved jumps from this graph result that match a
    /// specified kind.
    public func unresolvedJumps(ofKind kind: UnresolvedJump.Kind) -> [UnresolvedJump] {
        unresolvedJumps.filter { $0.kind == kind }
    }

    /// Performs a deep copy of this result, copying the graph, and all unresolved
    /// jumps.
    func copy() -> Self {
        var copy = self
        copy.graph = self.graph.copy()
        copy.unresolvedJumps = self.unresolvedJumps
        return copy
    }

    /// Returns a copy of this graph result which is the combination of the graph
    /// from this result, and `other`, connected entry-to-exit, like a standard
    /// "fall-through" statement flow.
    ///
    /// The entry node from this graph is the entry of the result, and the exit
    /// node of `other` is the new exit node.
    ///
    /// Unresolved jump list are concatenated in the result.
    func then(_ other: Self, debugLabel: String? = nil) -> Self {
        let copy = self.inserting(other)
        let edge = copy.graph.addEdge(from: exit, to: other.entry)
        edge.debugLabel = debugLabel
        copy.graph.exit = other.exit

        return copy
    }

    /// Returns a copy of this graph result with a branch added between two
    /// nodes contained within this graph.
    func branching(
        from start: ControlFlowGraphNode,
        to end: ControlFlowGraphNode,
        debugLabel: String? = nil
    ) -> Self {

        let copy = self.copy()
        let edge = copy.graph.addEdge(from: start, to: end)
        edge.debugLabel = debugLabel

        return copy
    }

    /// Returns a copy of this graph with the graph's exit point pointing to a
    /// graph that points back to another node in this same graph, forming a loop.
    ///
    /// If `conditional` is `true`, a branch between this graph's current exit
    /// node and the exit node of the resulting graph is left.
    func thenLoop(
        backTo node: ControlFlowGraphNode,
        conditionally conditional: Bool,
        debugLabel: String? = nil
    ) -> Self {

        let loopStart = exit

        let dummy = Self()

        let copy = self
            .then(dummy)
            .branching(
                from: loopStart,
                to: node,
                debugLabel: debugLabel
            )

        if !conditional {
            if copy.graph.areConnected(start: loopStart, end: dummy.entry) {
                copy.graph.removeEdge(from: loopStart, to: dummy.entry)
            }
        }

        return copy
    }

    /// Returns a copy of this graph result with all edges that point to a given
    /// node redirected to point to a given target node, instead.
    func redirectingEntries(
        for source: ControlFlowGraphNode,
        to target: ControlFlowGraphNode,
        debugLabel: String? = nil
    ) -> Self {

        let copy = self.copy()
        copy.graph.redirectEntries(for: source, to: target).setDebugLabel(debugLabel)

        return copy
    }

    /// Returns a copy of this graph result with all edges that start from a given
    /// node redirected to point to a given target node, instead.
    func redirectingExits(
        for source: ControlFlowGraphNode,
        to target: ControlFlowGraphNode,
        debugLabel: String? = nil
    ) -> Self {

        let copy = self.copy()
        copy.graph.redirectExits(for: source, to: target).setDebugLabel(debugLabel)

        return copy
    }

    /// Returns a copy of this graph result which is the combination of the graph
    /// from this result, and `other`, unconnected.
    ///
    /// The entry and exit of the resulting graph will still be the entry/exit
    /// from `self`.
    ///
    /// Unresolved jump list are concatenated in the result.
    func inserting(_ other: Self) -> Self {
        var copy = self.copy()
        copy.graph.merge(
            with: other.graph,
            ignoreEntryExit: false,
            ignoreRepeated: true
        )
        copy.unresolvedJumps.append(contentsOf: other.unresolvedJumps)

        return copy
    }

    /// Returns a copy of this graph result which is the combination of the graph
    /// from this result, and `other`, connecting the entry node of the incoming
    /// graph with all unresolved jumps within this result that match the provided
    /// kind, and creating an edge between the incoming graph's exit node and
    /// this result's graph's exit node.
    ///
    /// The entry node from this graph is the entry of the result, and the exit
    /// node of `self` remains the exit node.
    ///
    /// Unresolved jump list are concatenated in the result.
    func resolvingJumps(
        kind: UnresolvedJump.Kind,
        to other: Self,
        debugLabel: String? = nil
    ) -> Self {

        var copy = self.inserting(other)
        copy.resolveJumps(kind: kind, to: other.entry, debugLabel: debugLabel)
        copy.graph.addEdge(from: other.exit, to: exit)

        return copy
    }

    /// Returns a copy of this graph with a set of defer subgraphs appended to
    /// all jump nodes.
    ///
    /// The subgraphs are provided on-demand by a closure which gets executed
    /// for each jump node that requires an independent defer structure.
    func appendingLazyDefersToJumps(_ closure: () -> [CFGVisitResult]) -> Self {
        var copy = self.copy()

        for jump in copy.unresolvedJumps {
            let subgraphs = closure()
            let deferSubgraph = subgraphs.reduce(Self()) { $0.then($1) }

            copy = copy.inserting(deferSubgraph)

            copy.graph.redirectEntries(for: jump.node, to: deferSubgraph.entry)
            copy.graph.addEdge(from: deferSubgraph.exit, to: jump.node)
        }

        return copy
    }

    /// Returns a copy of this CFG result, with any entry/exit nodes that are
    /// in the middle of a flow expanded in many-to-many fashion.
    func finalized() -> Self {
        let copy = self.copy()

        for node in copy.graph.nodes {
            if node === copy.graph.entry || node === copy.graph.exit {
                continue
            }

            if node is ControlFlowGraphEntryNode || node is ControlFlowGraphExitNode {
                _expandAndRemove(node: node, in: copy.graph)
            }
        }

        return copy
    }

    /// Removes all edges that point to the exit of this CFG result.
    mutating func removeExitEdges() {
        graph.removeEntryEdges(towards: exit)
    }

    func resolvingJumpsToExit(
        kind: UnresolvedJump.Kind,
        debugLabel: String? = nil
    ) -> Self {
        var copy = self.copy()
        copy.resolveJumpsToExit(kind: kind, debugLabel: debugLabel)
        return copy
    }

    mutating func resolveJumpsToExit(
        kind: UnresolvedJump.Kind,
        debugLabel: String? = nil
    ) {
        resolveJumps(kind: kind, to: exit, debugLabel: debugLabel)
    }

    func resolvingJumps(
        kind: UnresolvedJump.Kind,
        to node: ControlFlowGraphNode,
        debugLabel: String? = nil
    ) -> Self {
        var copy = self.copy()
        copy.resolveJumps(kind: kind, to: node, debugLabel: debugLabel)
        return copy
    }

    mutating func resolveJumps(
        kind: UnresolvedJump.Kind,
        to node: ControlFlowGraphNode,
        debugLabel: String? = nil
    ) {
        func predicate(_ jump: UnresolvedJump) -> Bool {
            jump.kind == kind
        }

        for jump in unresolvedJumps.filter(predicate) {
            jump.resolve(to: node, in: graph, debugLabel: debugLabel)
        }

        unresolvedJumps.removeAll(where: predicate)
    }

    /// Returns a new graph a given list of jumps locally on this graph result.
    /// Jump nodes that are not present in this graph are added prior to resolution,
    /// and existing unresolved jumps that match node-wise with jumps from the
    /// given list are removed.
    func resolvingJumps(
        _ jumps: [UnresolvedJump],
        to node: ControlFlowGraphNode,
        debugLabel: String? = nil
    ) -> Self {
        var copy = self.copy()
        copy.resolveJumps(jumps, to: node, debugLabel: debugLabel)

        return copy
    }

    /// Resolves a given list of jumps locally on this graph result.
    /// Jump nodes that are not present in this graph are added prior to resolution,
    /// and existing unresolved jumps that match node-wise with jumps from the
    /// given list are removed.
    mutating func resolveJumps(
        _ jumps: [UnresolvedJump],
        to node: ControlFlowGraphNode,
        debugLabel: String? = nil
    ) {
        for jump in jumps {
            jump.resolve(to: node, in: graph, debugLabel: debugLabel)
        }

        unresolvedJumps.removeAll { u in
            jumps.contains { j in u.node === j.node }
        }
    }

    /// Returns a copy of this graph with all jumps from this graph result to a
    /// given node.
    func resolvingAllJumps(
        to node: ControlFlowGraphNode,
        debugLabel: String? = nil
    ) -> Self {
        var copy = self.copy()
        copy.resolveAllJumps(to: node, debugLabel: debugLabel)

        return copy
    }

    /// Resolves all jumps from this graph result to a given node.
    mutating func resolveAllJumps(
        to node: ControlFlowGraphNode,
        debugLabel: String? = nil
    ) {
        for jump in unresolvedJumps {
            jump.resolve(to: node, in: graph, debugLabel: debugLabel)
        }

        unresolvedJumps.removeAll()
    }

    /// Returns a copy of this graph with all jumps from this graph result to the
    /// current exit node.
    func resolvingAllJumpsToExit(debugLabel: String? = nil) -> Self {
        var copy = self.copy()
        copy.resolveAllJumpsToExit(debugLabel: debugLabel)

        return copy
    }

    /// Resolves all jumps from this graph result to the current exit node.
    mutating func resolveAllJumpsToExit(debugLabel: String? = nil) {
        for jump in unresolvedJumps {
            jump.resolve(to: exit, in: graph, debugLabel: debugLabel)
        }

        unresolvedJumps.removeAll()
    }

    /// Returns a copy of this subgraph with all jumps that match a specific
    /// kind removed.
    func removingJumps(kind: UnresolvedJump.Kind) -> Self {
        var copy = self.copy()
        copy.removeJumps(kind: kind)

        return copy
    }

    /// Removes all jumps that match a specific kind in this graph.
    mutating func removeJumps(kind: UnresolvedJump.Kind) {
        func predicate(_ jump: UnresolvedJump) -> Bool {
            jump.kind == kind
        }

        for jump in unresolvedJumps {
            if predicate(jump) {
                graph.removeNode(jump.node)
            }
        }

        unresolvedJumps.removeAll(where: predicate)
    }

    /// Replaces the labels of all edges pointing to the exit node of this
    /// result with a given value.
    mutating func labelExits(debugLabel: String?) {
        for edge in graph.edges(towards: exit) {
            edge.debugLabel = debugLabel
        }
    }

    /// Returns a copy of this result with all edges pointing to the exit node
    /// having a given debug label value.
    func labelingExits(debugLabel: String?) -> Self {
        var copy = self.copy()
        copy.labelExits(debugLabel: debugLabel)
        return copy
    }

    /// Replaces the labels of all edges pointing from the entry node of this
    /// result with a given value.
    mutating func labelEntries(debugLabel: String?) {
        for edge in graph.edges(from: entry) {
            edge.debugLabel = debugLabel
        }
    }

    /// Returns a copy of this result with all edges pointing from the entry node
    /// having a given debug label value.
    func labelingEntries(debugLabel: String?) -> Self {
        var copy = self.copy()
        copy.labelEntries(debugLabel: debugLabel)
        return copy
    }

    /// An unresolved jump from a CFG visit.
    public struct UnresolvedJump {
        /// The temporary node inserted to represent this unresolved jump in
        /// the graph.
        public let node: ControlFlowGraphUnresolvedJumpNode

        /// The kind of this unresolved jump.
        public let kind: Kind

        func resolve(
            to node: ControlFlowGraphNode,
            in graph: ControlFlowGraph,
            debugLabel: String? = nil
        ) {
            connect(to: node, in: graph, debugLabel: debugLabel)

            expandAndRemove(in: graph)
        }

        func expandAndRemove(in graph: ControlFlowGraph) {
            if graph.edges(from: node).isEmpty {
                fatalError(
                    "Attempted to remove unresolved jump \(kind) before connecting it to other nodes."
                )
            }

            _expandAndRemove(node: node, in: graph)
        }

        func connect(
            to target: ControlFlowGraphNode,
            in graph: ControlFlowGraph,
            debugLabel: String? = nil
        ) {
            if !graph.containsNode(node) {
                graph.addNode(node)
            }
            if !graph.containsNode(target) {
                graph.addNode(target)
            }

            if let existing = graph.edge(from: node, to: target) {
                if existing.debugLabel == nil {
                    existing.debugLabel = debugLabel
                }
            } else {
                let edge = graph.addEdge(from: node, to: target)
                edge.debugLabel = debugLabel
            }
        }

        public enum Kind: Equatable, CustomStringConvertible {
            /// A continue statement, with an optional label.
            case `continue`(label: String?)

            /// A break statement, with an optional label.
            case `break`(label: String?)

            /// A return statement.
            case `return`

            /// A throw in a throwable function.
            case `throw`

            /// A switch case's 'fallthrough'.
            case `fallthrough`

            /// Expression short-circuits, like boolean expression short circuiting
            /// or null-coalesce/optional member access expressions.
            case expressionShortCircuit

            // TODO: Consider collapsing switch case/conditional clause into one kind

            /// Used in switch statements to move between cases when their patterns
            /// fail.
            case switchCasePatternFail

            /// Used in conditional statements to bail out of a condition on each
            /// pattern.
            case conditionalClauseFail

            public var description: String {
                switch self {
                case .break(let label):
                    return "break \(label ?? "")"

                case .conditionalClauseFail:
                    return "conditionalClauseFail"

                case .continue(let label):
                    return "continue \(label ?? "")"

                case .expressionShortCircuit:
                    return "expressionShortCircuit"

                case .fallthrough:
                    return "fallthrough"

                case .return:
                    return "return"

                case .switchCasePatternFail:
                    return "switchCasePatternFail"

                case .throw:
                    return "throw"
                }
            }
        }
    }
}

/// A syntax node class used in marker nodes and entry/exit nodes of subgraphs.
class MarkerSyntaxNode: SyntaxNode {

}

private func _expandAndRemove(node: ControlFlowGraphNode, in graph: ControlFlowGraph) {
    guard graph.containsNode(node) else {
        return
    }

    let edgesToMarker = graph.edges(towards: node)
    let edgesFromMarker = graph.edges(from: node)

    graph.removeNode(node)

    for edgeTo in edgesToMarker {
        for edgeFrom in edgesFromMarker {
            if edgeTo.start === node && edgeTo.end === node {
                fatalError("Expanding self-referential nodes is not supported: \(node)")
            }

            guard !graph.areConnected(start: edgeTo.start, end: edgeFrom.end) else {
                continue
            }

            let edge = graph.addEdge(from: edgeTo.start, to: edgeFrom.end)

            switch (edgeTo.debugLabel, edgeFrom.debugLabel) {
            case (let labelTo?, let labelFrom?):
                edge.debugLabel = "\(labelTo)/\(labelFrom)"

            case (nil, let label?), (let label?, nil):
                edge.debugLabel = label

            case (nil, nil):
                break
            }
        }
    }
}

internal extension CFGVisitResult {
    func debugPrint() {
        let viz = self.graph.asGraphviz()
        print(viz.generateFile())
    }
}
