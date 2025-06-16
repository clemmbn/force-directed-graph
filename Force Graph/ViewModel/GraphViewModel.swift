//
//  GraphViewModel.swift
//  ForceDirectedGraph (iOS)
//
//  Created by Ray Fix on 11/26/21.
//

import Combine
import CoreGraphics.CGAffineTransform

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

final class GraphViewModel: ObservableObject {
  
  // Constants for the graph
  enum Constant {
    static let nodeSize = 20.0
    static let fontSize = 12.0
    static let linkWidth = 2.0
  }
  
  // Graph store
  var graph: GraphStore

  // When the canvas size changes, this property updates the coordinate transformations:
  // - Centers the graph in the canvas
  // - Scales the graph to fit within the minimum dimension
  // - Maintains both model-to-view and view-to-model transforms
  var canvasSize: CGSize = .zero {
    didSet {
      let minDimension = min(canvasSize.width, canvasSize.height)
      
      // 2) Center the graph in the canvas by translating by half the difference between the canvas size and the minimum dimension
      modelToView = CGAffineTransform.identity
        .translatedBy(x: (canvasSize.width - minDimension) * 0.5,
                      y: (canvasSize.height - minDimension) * 0.5)
      // 1) Scale the graph to fit within the minimum dimension
        .scaledBy(x: minDimension, y: minDimension)
      // 3) Update the view to model and model to view transforms
      viewToModel = modelToView.inverted()
    }
  }
    
  // When the layout changes, the layout engine is updated
  var layout = Layout.circular {
    didSet {
      layoutEngine = layout.makeEngine()
    }
  }
  private var layoutEngine: GraphLayout = CircularGraphLayout()
  
  // Initializes the graph with a graph store
  init(_ graph: GraphStore) {
      self.graph = graph
  }
  
  // Initializes the view to model and model to view transforms with the identity transform
  private(set) var viewToModel: CGAffineTransform = .identity
  private(set) var modelToView: CGAffineTransform = .identity
  
  // Initializes the link width model
  var linkWidthModel: Double {
    Constant.linkWidth * viewToModel.a
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

  // Creates an array of link segments
  // - Converts the link's source and target positions from model coordinates to view coordinates
  // - Returns an array of tuples containing the source and target positions
  func linkSegments() -> [(CGPoint, CGPoint)] {
    let lookup = Dictionary(uniqueKeysWithValues:
                              graph.nodes.map { ($0.id, $0.position) })
    return graph.links.compactMap { link in
      guard let source = lookup[link.source],
            let target = lookup[link.target] else {
              return nil
            }
      return (source, target)
    }
  }
  
  // Updates the simulation
  // - Calls the layout engine to update the graph
  func updateSimulation() {
    layoutEngine.update(graph: &graph)
  }
}
