import MiniDigraph
import SwiftAST

/// Class that represents control flow graphs (CFGs) of Swift functions.
public final class ControlFlowGraph: DirectedGraphBase<ControlFlowGraphNode, ControlFlowGraphEdge> {
    /// The entry point of this control flow graph
    internal(set) public var entry: ControlFlowGraphEntryNode
    /// The exit point of this control flow graph
    internal(set) public var exit: ControlFlowGraphExitNode

    /// Counter used to differentiate nodes in the graph as they are added.
    var idCounter: Int = 0

    /// Returns `true` if the only nodes in this graph are the entry and exit
    /// nodes, and marker nodes.
    var isEmpty: Bool {
        return nodes.allSatisfy { node in
            node === entry || node === exit
        }
    }

    init(entry: ControlFlowGraphEntryNode, exit: ControlFlowGraphExitNode) {
        self.entry = entry
        self.exit = exit

        super.init(nodes: [], edges: [])

        addNode(entry)
        addNode(exit)
    }

    @available(*, unavailable, message: "Initialize ControlFlowGraph with 'init(entry:exit:)', instead.")
    required convenience init() {
        fatalError("init() has not been implemented")
    }

    @available(*, unavailable, message: "Cannot make arbitrary subgraphs of a ControlFlowGraph.")
    public override func subgraph<S>(of nodes: S) -> Self where S: Sequence, S.Element == Node {
        fatalError("Cannot take subgraphs of a ControlFlowGraph")
    }

    /// Returns the next available node ID and increments the counter by 1.
    func nextId() -> Int {
        defer { idCounter += 1 }
        return idCounter
    }

    /// Returns the control flow graph node that represents a given syntax node,
    /// if available.
    /// Returns `nil`, if no graph node represents the given syntax node directly.
    ///
    /// A reference equality test (===) is used to determine syntax node equality.
    public func graphNode(for node: SyntaxNode) -> Node? {
        nodes.first { $0.node === node }
    }

    /// Returns the control flow graph node that represents a given syntax node,
    /// or any of its ancestors.
    /// When searching across ancestors, the nearest ancestors are searched first.
    ///
    /// A reference equality test (===) is used to determine syntax node equality.
    public func graphNode(forFirstAncestorOf node: SyntaxNode) -> Node? {
        var current: SyntaxNode? = node

        while let c = current {
            if let result = graphNode(for: node) {
                return result
            }

            current = c.parent
        }

        return nil
    }

    // MARK: - Internals

    override func copyMetadata(from node1: Node, to node2: Node) {

    }

    override func copyMetadata(from edge1: Edge, to edge2: Edge) {
        edge2.debugLabel = edge1.debugLabel
        edge2.isBackEdge = edge1.isBackEdge
    }

    /// Removes all nodes and edges from this control flow graph.
    ///
    /// The graph is reset to an empty graph with just the entry and exit nodes.
    override func clear() {
        super.clear()

        nodes = [entry, exit]
    }

    /// Adds a given node to this graph.
    override func addNode(_ node: Node) {
        if let subgraph = node as? ControlFlowSubgraphNode {
            assert(
                subgraph.graph !== self,
                "Adding a graph as a subnode of itself!"
            )
        }

        super.addNode(node)
    }

    /// Adds an edge `start -> end` to this graph.
    @discardableResult
    override func addEdge(from start: Node, to end: Node) -> Edge {
        assert(
            containsNode(start),
            "Attempted to add edge between nodes that are not contained within this graph: \(start)."
        )
        assert(
            containsNode(end),
            "Attempted to add edge between nodes that are not contained within this graph: \(end)."
        )

        let edge = Edge(start: start, end: end)
        addEdge(edge)

        return edge
    }
}

// MARK: - Internals - extension

extension ControlFlowGraph {
    /// Returns a list of nodes collected in depth-first order
    func depthFirstList() -> [Node] {
        var list: [Node] = []

        depthFirstVisit(start: entry) {
            list.append($0.node)
            return true
        }

        return list
    }

    /// Returns a list of nodes collected in breadth-first order
    func breadthFirstList() -> [Node] {
        var list: [Node] = []

        breadthFirstVisit(start: entry) {
            list.append($0.node)
            return true
        }

        return list
    }
}

extension ControlFlowGraph {
    /// Returns a copy of this control flow graph, containing the same node
    /// references as the current graph.
    func copy() -> ControlFlowGraph {
        let copy = ControlFlowGraph(entry: entry, exit: exit)
        copy.nodes = nodes

        for edge in edges {
            let edgeCopy = copy.addEdge(from: edge.start, to: edge.end)
            copyMetadata(from: edge, to: edgeCopy)
        }

        return copy
    }

    /// Performs a deep-copy of this control flow graph, returning a CFG that
    /// points to the same syntax node references, but has independent edge/node
    /// reference identities.
    func deepCopy() -> ControlFlowGraph {
        let copy = ControlFlowGraph(entry: entry, exit: exit)
        copy.nodes = Set(nodes.map({ $0.copy() }))

        for edge in edges {
            let edgeCopy = copy.addEdge(from: edge.start, to: edge.end)
            copyMetadata(from: edge, to: edgeCopy)
        }

        return copy
    }

    /// Merges another graph's nodes and edges into this graph.
    ///
    /// If `ignoreEntryExit` is `true` (default), the entry and exit nodes from
    /// the other graph are not merged, and any connection from and to the entry
    /// and exit are not copied.
    ///
    /// If `ignoreRepeated` is `true`, nodes and edges that already exist in this
    /// graph are not added.
    func merge(
        with other: ControlFlowGraph,
        ignoreEntryExit: Bool = true,
        ignoreRepeated: Bool = false
    ) {

        assert(other !== self, "attempting to merge a graph with itself!")

        func shouldMerge(_ node: Node) -> Bool {
            if !ignoreEntryExit {
                return true
            }

            return node !== other.entry && node !== other.exit
        }

        let nodes = other.nodes.filter(shouldMerge)

        let edges = other.edges.filter {
            shouldMerge($0.start) && shouldMerge($0.end)
        }

        for node in nodes {
            if ignoreRepeated && containsNode(node) {
                continue
            }

            addNode(node)
        }
        for edge in edges {
            if ignoreRepeated {
                guard containsNode(edge.start) && containsNode(edge.end) else {
                    continue
                }
                if let existing = self.edges(from: edge.start, to: edge.end).first {
                    copyMetadata(from: edge, to: existing)
                    continue
                }
            }

            let e = addEdge(from: edge.start, to: edge.end)
            copyMetadata(from: edge, to: e)
        }
    }
}

// MARK: - Debug internals

internal extension ControlFlowGraph {
    func dumpState() -> String {
        var buffer: String = ""

        for node in nodes {
            print(node, to: &buffer)
        }

        print(to: &buffer)

        for edge in edges {
            print("\(edge.start) -> \(edge.end)", terminator: "", to: &buffer)
            if let debugLabel = edge.debugLabel {
                print(" (\(debugLabel))", terminator: "", to: &buffer)
            }

            print(to: &buffer)
        }

        return buffer
    }
}

// MARK: - Utilities

internal extension ControlFlowGraph {
    /// Prunes this control flow graph, removing any nodes that are unreachable
    /// from its initial node.
    func prune() {
        var toRemove: Set<Node> = Set(nodes)

        breadthFirstVisit(start: entry) { visit in
            toRemove.remove(visit.node)

            return true
        }

        toRemove.forEach(removeNode)
    }

    /// Marks back edges for a graph.
    ///
    /// A back edge is an edge that connects one node to another node that comes
    /// earlier in the graph when visiting the graph in breadth-first fashion
    /// starting from its entry point.
    func markBackEdges() {
        var visited: Set<Node> = []

        breadthFirstVisit(start: entry) { visit in
            for nextEdge in edges(from: visit.node) {
                let node = endNode(for: nextEdge)
                if visit.allNodes.contains(node) {
                    nextEdge.isBackEdge = true
                }
            }

            visited.insert(visit.node)

            return true
        }
    }

    /// Expands subgraph nodes in this graph, performing a many-to-many expansion
    /// of the edges going in and out of the subgraph node.
    func expandSubgraphs() {
        for case let node as ControlFlowSubgraphNode in nodes {
            let edgesTo = edges(towards: node)
            let edgesFrom = edges(from: node)

            let entryEdges = node.graph.edges(from: node.graph.entry)
            let exitEdges = node.graph.edges(towards: node.graph.exit)

            removeNode(node)

            merge(with: node.graph)

            for edgeTo in edgesTo {
                let source = edgeTo.start

                for entryEdge in entryEdges {
                    let target = entryEdge.end

                    let edge = addEdge(from: source, to: target)
                    edge.isBackEdge = edgeTo.isBackEdge
                    edge.debugLabel = edgeTo.debugLabel
                }
            }
            for edgeFrom in edgesFrom {
                let target = edgeFrom.end

                for exitEdge in exitEdges {
                    let source = exitEdge.start

                    let edge = addEdge(from: source, to: target)
                    edge.isBackEdge = edgeFrom.isBackEdge
                    edge.debugLabel = edgeFrom.debugLabel
                }
            }
        }
    }
}

/// Specifies a control flow graph node
public class ControlFlowGraphNode: Hashable, CustomStringConvertible {
    /// An associated node for this control flow graph node.
    public let node: SyntaxNode

    /// An extra identifier used to differentiate nodes of the same label on a graph.
    /// Has no requirement to be unique amongst all nodes, and is mainly used
    /// during Graphviz generation.
    public let id: Int

    public var description: String {
        "{node: \(type(of: node)): \(node) {\(id)}}"
    }

    init(node: SyntaxNode, id: Int) {
        self.node = node
        self.id = id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
        hasher.combine(ObjectIdentifier(node))
        hasher.combine(id)
    }

    /// Returns a copy of this graph node, pointing to the same underlying
    /// syntax node reference.
    public func copy() -> ControlFlowGraphNode {
        ControlFlowGraphNode(node: node, id: id)
    }

    public static func == (lhs: ControlFlowGraphNode, rhs: ControlFlowGraphNode) -> Bool {
        //type(of: lhs) == type(of: rhs) && lhs.node === rhs.node
        lhs === rhs && lhs.id == rhs.id
    }
}

/// A graph node which serves as a temporary marker for unresolved jumps.
public final class ControlFlowGraphUnresolvedJumpNode: ControlFlowGraphNode {
    /// The debug label associated with this node.
    public let debugLabel: String

    init(node: SyntaxNode, id: Int, debugLabel: String) {
        self.debugLabel = debugLabel

        super.init(node: node, id: id)
    }

    public override func copy() -> ControlFlowGraphNode {
        ControlFlowGraphUnresolvedJumpNode(
            node: node,
            id: id,
            debugLabel: debugLabel
        )
    }
}

/// Represents an entry node for a control flow graph
public final class ControlFlowGraphEntryNode: ControlFlowGraphNode {
    public override var description: String {
        "{entry: \(type(of: node)): \(node)}"
    }

    public init(node: SyntaxNode) {
        super.init(node: node, id: 1)
    }

    public override func copy() -> ControlFlowGraphEntryNode {
        ControlFlowGraphEntryNode(node: node)
    }
}

/// Represents an exit node for a control flow graph
public final class ControlFlowGraphExitNode: ControlFlowGraphNode {
    public override var description: String {
        "{exit: \(type(of: node)): \(node)}"
    }

    public init(node: SyntaxNode) {
        super.init(node: node, id: 1)
    }

    public override func copy() -> ControlFlowGraphExitNode {
        ControlFlowGraphExitNode(node: node)
    }
}

/// A graph node which contains a complete subgraph
public final class ControlFlowSubgraphNode: ControlFlowGraphNode {
    /// An associated node for this control flow graph node.
    public let graph: ControlFlowGraph

    init(node: SyntaxNode, graph: ControlFlowGraph, id: Int) {
        self.graph = graph

        super.init(node: node, id: id)
    }

    public override func copy() -> ControlFlowGraphNode {
        ControlFlowSubgraphNode(node: node, graph: graph.deepCopy(), id: id)
    }
}

/// A graph node that signifies the end of a definition scope.
public final class ControlFlowGraphEndScopeNode: ControlFlowGraphNode {
    /// An associated code scope for this control flow graph node.
    public let scope: CodeScopeNodeType

    init(node: SyntaxNode, scope: CodeScopeNodeType, id: Int) {
        self.scope = scope

        super.init(node: node, id: id)
    }

    public override func copy() -> ControlFlowGraphNode {
        ControlFlowGraphEndScopeNode(node: node, scope: scope, id: id)
    }
}

/// Represents a directed edge in a control flow graph.
public final class ControlFlowGraphEdge: DirectedGraphBaseEdgeType {
    public let start: ControlFlowGraphNode
    public let end: ControlFlowGraphNode

    /// True if this is a back edge which points backwards towards the start of
    /// a flow
    public var isBackEdge: Bool = false

    /// A label that can be used during debugging to discern CFG edges.
    public var debugLabel: String?

    init(start: ControlFlowGraphNode, end: ControlFlowGraphNode) {
        self.start = start
        self.end = end
    }

    /// Returns a copy of this control flow graph edge.
    ///
    /// The new edge object references the same underlying node references.
    public func copy() -> ControlFlowGraphEdge {
        ControlFlowGraphEdge(start: start, end: end)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(start))
        hasher.combine(ObjectIdentifier(end))
    }

    public static func == (lhs: ControlFlowGraphEdge, rhs: ControlFlowGraphEdge) -> Bool {
        //type(of: lhs) == type(of: rhs) && lhs.node === rhs.node
        lhs === rhs
    }
}

extension Sequence where Element: ControlFlowGraphEdge {
    @discardableResult
    func setDebugLabel(_ debugLabel: String?) -> [Element] {
        map {
            $0.debugLabel = debugLabel ?? $0.debugLabel
            return $0
        }
    }
}
