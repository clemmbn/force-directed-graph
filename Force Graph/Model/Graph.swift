//
//  Edge.swift
//  MyTestfield
//
//  Created by Clément Maubon on 13/06/2025.
//

import Foundation
import CoreGraphics

@Observable
final class GraphStore {
    var nodes: [Node] = []
    var edges: [Edge] = []
    var adjacency: [UUID: Set<UUID>] = [:]

    // Normalized space
    var position: CGPoint
    var velocity: CGPoint
    var isInteractive: Bool

    // Constants for the graph
    enum Constant {
        static let nodeSize = 20.0
        static let fontSize = 12.0
        static let edgeWidth = 2.0
        static let timeStep = 0.5
    }
    
    // Initializes the view to model and model to view transforms with the identity transform
    private(set) var viewToModel: CGAffineTransform = .identity
    private(set) var modelToView: CGAffineTransform = .identity
    
    init(nodes: [Node], edges: [Edge]) {
        self.nodes = nodes
        self.edges = edges
        self.adjacency = buildAdjacencyList(from: edges)
    }

    // MARK: - Public Methods

    // When the canvas size changes, this property updates the coordinate transformations:
    // - Centers the graph in the canvas
    // - Scales the graph to fit within the minimum dimension
    // - Maintains both model-to-view and view-to-model transforms
    func updateCanvasSize(_ size: CGSize) {
        let minDimension = min(size.width, size.height)
      
        // 2) Center the graph in the canvas by translating by half the difference between the canvas size and the minimum dimension
        modelToView = CGAffineTransform.identity
            .translatedBy(x: (size.width - minDimension) * 0.5,
                        y: (size.height - minDimension) * 0.5)
        // 1) Scale the graph to fit within the minimum dimension
            .scaledBy(x: minDimension, y: minDimension)
        // 3) Update the view to model and model to view transforms
        viewToModel = modelToView.inverted()
    }

    // Hit tests a point in view coordinates to find the index of the node it intersects with
    func hitTest(point: CGPoint) -> Int? {
        // Convert the point from view coordinates to model coordinates
        let modelPoint = point.applying(viewToModel)
        return graph.nodes.firstIndex { modelRect(node: $0).contains(modelPoint) }
    }
    
    // Drags a node to a new position
    // - Converts the location from view coordinates to model coordinates
    // - Updates the node's position, velocity, and interactive state
    func dragNode(at index: Int, location: CGPoint) {
        let point = location.applying(viewToModel)
        graph.nodes[index].position = point
        graph.nodes[index].velocity = .zero
        graph.nodes[index].isInteractive = true
    }
    
    // Stops dragging a node
    // - Sets the node's interactive state to false
    func stopDraggingNode(at index: Int) {
        graph.nodes[index].isInteractive = false
    }

    // MARK: - Private Methods
    
    // Builds the adjacency list for the graph
    private func buildAdjacencyList(from edges: [Edge]) -> [UUID: Set<UUID>] {
        edges.reduce(into: [:]) { result, edge in
            result[edge.sourceID, default: []].insert(edge.targetID)
            result[edge.targetID, default: []].insert(edge.sourceID)
        }
    }

    // Creates a hit-testing rectangle for a node in model coordinates
    // - Starts with a zero-sized rectangle at the node's position
    // - Expands it by half the node size in each direction
    // - Scales the size based on the current view transformation
    // - Used for hit testing to determine if a touch/click is within a node's bounds
    func modelRect(node: Node) -> CGRect {
        let inset = -Constant.nodeSize / (modelToView.a * 2)
        return CGRect(origin: node.position, size: .zero)
        .insetBy(dx: inset, dy: inset)
    }
    
    // convenience sample data for previews
    static func sample() -> GraphStore {
        let n1 = Node(position: CGPoint(x: 100, y: 100))
        let n2 = Node(position: CGPoint(x: 250, y: 150), shape: .square)
        let n3 = Node(position: CGPoint(x: 180, y: 300))
        let e1 = Edge(sourceID: n1.id, targetID: n2.id)
        let e2 = Edge(sourceID: n2.id, targetID: n3.id)
        let e3 = Edge(sourceID: n3.id, targetID: n1.id)
        
        return GraphStore(nodes: [n1, n2, n3], edges: [e1, e2, e3])
    }
}

// MARK: - Supporting Types

// A node represents a vertex of the graph (a dot)
struct Node: Identifiable, Hashable {
    let id = UUID()
    var position: CGPoint
    var shape: NodeShape = .circle
}

// An edge links two nodes
struct Edge: Identifiable, Hashable {
    let id = UUID()
    let sourceID: UUID
    let targetID: UUID
}

enum NodeShape {
    case circle, square
}
