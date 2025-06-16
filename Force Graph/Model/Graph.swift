//
//  Edge.swift
//  MyTestfield
//
//  Created by Clément Maubon on 13/06/2025.
//

import Foundation

@Observable
final class GraphStore {
    //Large graphs need constant-time access to a node; a dictionary keyed by UUID is cheap. Arrays alone would force O(n) scans.
    var nodesByID: [UUID : Node] = [:]
    var edges: [Edge] = []
    var adjacency: [UUID: Set<UUID>] = [:]
    
    
    init(nodes: [Node], edges: [Edge]) {
        self.nodesByID = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        self.edges = edges
        self.adjacency = edges.reduce(into: [:]) { result, edge in
            if result[edge.sourceID] == nil {
                result[edge.sourceID] = []
            }
            if result[edge.targetID] == nil {
                result[edge.targetID] = []
            }
            result[edge.sourceID]!.insert(edge.targetID)
            result[edge.targetID]!.insert(edge.sourceID)
        }
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

struct Node: Identifiable, Hashable {
    let id = UUID()
    var position: CGPoint
    var shape: NodeShape = .circle
    var size: CGFloat = 50
}

struct Edge: Identifiable, Hashable {
    let id = UUID()
    let sourceID: UUID
    let targetID: UUID
}

enum NodeShape {
    case circle, square
}
