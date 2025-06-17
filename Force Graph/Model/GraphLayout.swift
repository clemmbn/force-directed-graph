//
//  ForceDirectedLayout.swift
//
//  Created by Ray Fix on 7/19/19.
//  Copyright © 2019-2021 Ray Fix. All rights reserved.
//

import Foundation
import CoreGraphics.CGAffineTransform // Verify if needed

/// A way to compute
protocol GraphLayout {
  func update(graph: inout Graph)
}

// Enum for the different layouts of the graph
enum Layout: Int, Hashable {
  case circular, forceDirected
    
  func makeEngine() -> GraphLayout {
    switch self {
    case .circular:
      return CircularGraphLayout()
    case .forceDirected:
      return ForceDirectedGraphLayout()
    }
  }
}

// MARK: - Layout Engines

// Circular Graph Layout
final class CircularGraphLayout: GraphLayout {
  var startAngle = 0.0
  
  func update(graph: inout Graph) {
    let radius = 0.4
    let center = CGPoint(0.5, 0.5)
    let delta = 2 * CGFloat.pi / CGFloat(graph.nodes.count)
    
    var angle = startAngle
    for index in graph.nodes.indices {
      defer { angle += delta }
      guard !graph.nodes[index].isInteractive else { continue }
      graph.nodes[index].position = center +
      CGPoint(cos(Double(angle)),
              sin(Double(angle))) * radius
      graph.nodes[index].velocity = .zero
      
    }
    startAngle += 0.005
  }
}

// Force-directed Graph Layout
struct ForceDirectedGraphLayout: GraphLayout {
  
  let friction = 0.001
  let springLength = 0.15
  let springConstant = 40.0
  let chargeConstant = 0.05875
  
  // Computes the spring forces between a source node and its targets
  private func computeSpringForces(source: CGPoint, targets: [CGPoint]) -> CGPoint {

    var accum = CGPoint.zero // Accumulator for the spring forces
    
    // Iterate over the targets and compute the spring forces
    for target in targets {
      let delta = target - source // Vector from source to target
      let length = delta.distance // Distance between source and target
      guard length > 0 else { continue } // Skip if the distance is zero
      let unit = delta / length // Unit vector in the direction of the target
      accum += unit * (length-springLength) * springConstant // Spring force F = k * (l - l0)
    }
    
    return accum
  }
  
  // Computes the repulsion forces between a reference node and other nodes
  private func computeRepulsion(at reference: CGPoint, from others: [CGPoint], skipIndex: Int) -> CGPoint {
    
    var accum = CGPoint.zero // Accumulator for the repulsion forces
    
    // Iterate over the other nodes and compute the repulsion forces
    // "offset" is the index of the other node in the array
    // "other" is the position of the other node
    for (offset, other) in others.enumerated() {
      guard offset != skipIndex else { continue } // Skip the reference node
      let diff = reference - other // Vector from reference to other
      guard diff.distanceSquared > 1e-8 else { continue } // Skip if the distance is zero
      accum += diff / diff.distanceSquared * chargeConstant // Repulsion force F = k * (1/r^2)
    }
    return accum
  }
  
  // Updates the positions and velocities of the nodes in the graph
  func update(graph: inout Graph) {
    
    var positions = graph.nodes.map { $0.position } // Get the positions of the nodes
    var velocities = graph.nodes.map { $0.velocity } // Get the velocities of the nodes
    
    // Create a lookup table to map node IDs to their indices
    let lookup = Dictionary(uniqueKeysWithValues:
                              graph.nodes.enumerated().map { ($0.element.id, $0.offset) })

    // Create a table to store the targets for each node
    var targets: [[CGPoint]] = Array(repeating: [], count: positions.count)

    // Iterate over the edges and compute the targets for each node
    for edge in graph.edges {
      guard let source = lookup[edge.sourceID],
            let target = lookup[edge.targetID] else { continue }
      targets[source].append(positions[target]) // Add the target to the source's targets
      targets[target].append(positions[source]) // Add the source to the target's targets
    }
    
    // Create an array of zeros to store the forces for each node
    var forces = Array(repeating: CGPoint.zero, count: positions.count)
    
    // Iterate over the nodes and compute the forces for each node
    for (offset, position) in positions.enumerated() {
      forces[offset] += computeRepulsion(at: position, from: positions, skipIndex: offset)
      forces[offset] += computeSpringForces(source: position, targets: targets[offset])
    }
    
    // Centering force
    let centering = CGPoint(0.5, 0.5) - (positions.meanPoint() ?? .zero)
    
    // Integrate the forces to get velocities
    for (index, velocity) in velocities.enumerated() {
      let new = (velocity + forces[index] * Constant.timeStep) * friction
      velocities[index] = new // Update the velocity
    }
    
    // Update positions based on velocities and centering force
    for index in positions.indices {
        // If the node is being dragged by the user, freeze it in place
        if graph.nodes[index].isInteractive {
            velocities[index] = .zero  // Stop any movement
            continue
        }
        
        // Euler integration: position += velocity * dt + centering_force
        // Note: We're adding centering directly to position which is a bit of a hack,
        // but it works as a gentle pull toward the center
        positions[index] += velocities[index] + centering
    }
    
    // Copy them in
    for index in positions.indices {
      graph.nodes[index].position = positions[index]
      graph.nodes[index].velocity = velocities[index]
    }
  }
}

