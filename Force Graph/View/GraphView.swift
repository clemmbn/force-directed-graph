//
//  GraphView.swift
//  MyTestfield
//
//  Created by Clément Maubon on 13/06/2025.
//


import SwiftUI

struct GraphView: View {
    @State var store: GraphStore
    @StateObject var viewModel: GraphViewModel
    
    @State var isDragging = false
    @State var draggingIndex: Int?
    @State var previous: Date?

    // Pan & zoom state
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureTranslation: CGSize = .zero
    
    let minScale: CGFloat = 0.25   // 25 % of original size
    let maxScale: CGFloat = 4.0    // 400 %
    
    var drag: some Gesture {
      let tap = DragGesture(minimumDistance: 0, coordinateSpace: .local)
        .onChanged { drag in
          if isDragging, let index = draggingIndex {
            viewModel.dragNode(at: index, location: drag.location)
          } else {
            draggingIndex = viewModel.hitTest(point: drag.location)
          }
          isDragging = true
        }
        .onEnded { _ in
          if let index = draggingIndex {
            viewModel.stopDraggingNode(at: index)
          }
          isDragging = false
          draggingIndex = nil
        }
      return tap
    }

    var body: some View {
        // --- Compute world‑space extremes (centres only) ---
        let xs = store.nodesByID.values.map { $0.position.x }
        let ys = store.nodesByID.values.map { $0.position.y }
        let minWorldX = xs.min() ?? 0
        let maxWorldX = xs.max() ?? 0
        let minWorldY = ys.min() ?? 0
        let maxWorldY = ys.max() ?? 0
        let margin: CGFloat = 10
        
        GeometryReader { geo in
            
            let dragGesture = DragGesture()
                .updating($gestureTranslation) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    let newOffsetWidth  = offset.width  + value.translation.width
                    let newOffsetHeight = offset.height + value.translation.height
                    
                    // Re‑compute scaled bounds with the *current* scale
                    let scaledMinX = minWorldX * scale
                    let scaledMaxX = maxWorldX * scale
                    let scaledMinY = minWorldY * scale
                    let scaledMaxY = maxWorldY * scale
                    
                    let minOffsetX = (geo.size.width  - margin) - scaledMaxX
                    let maxOffsetX = margin - scaledMinX
                    let minOffsetY = (geo.size.height - margin) - scaledMaxY
                    let maxOffsetY = margin - scaledMinY
                    
                    print("Min offset X: \(minOffsetX) and max : \(maxOffsetX)")
                    
                    withAnimation(.spring) {
                        offset.width  = newOffsetWidth
                        offset.height = newOffsetHeight.clamped(to: minWorldY...maxWorldY)
                    }
                }

//            let magnificationGesture = MagnificationGesture()
//                .updating($gestureScale) { value, state, _ in
//                    state = value
//                }
//                .onEnded { value in
//                    // Clamp scale first
//                    let newScale = (scale * value).clamped(to: minScale...maxScale)
//                    scale = newScale
//                    
//                    // Re‑compute scaled bounds with *new* scale and clamp offset
//                    let scaledMinX = minWorldX * newScale
//                    let scaledMaxX = maxWorldX * newScale
//                    let scaledMinY = minWorldY * newScale
//                    let scaledMaxY = maxWorldY * newScale
//                    
//                    let minOffsetX = (geo.size.width  - margin) - scaledMaxX
//                    let maxOffsetX = margin - scaledMinX
//                    let minOffsetY = (geo.size.height - margin) - scaledMaxY
//                    let maxOffsetY = margin - scaledMinY
//                    
//                    withAnimation(.spring) {
//                        offset.width  = offset.width
//                        offset.height = offset.height
//                    }
//                }
//
//            let combined = dragGesture.simultaneously(with: magnificationGesture)
            
            ZStack {
                // Edges layer
                Canvas { context, _ in
                    for edge in store.edges {
                        guard
                            let a = store.nodesByID[edge.sourceID]?.position,
                            let b = store.nodesByID[edge.targetID]?.position
                        else { continue }
                        
                        var path = Path()
                        path.move(to: a)
                        path.addLine(to: b)
                        
                        context.stroke(
                            path,
                            with: .color(.primary.opacity(0.5)),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                    }
                }

                // Nodes layer
                ForEach(store.nodesByID.values.sorted(by: { $0.id.uuidString < $1.id.uuidString })) { node in
                    NodeView(node: node)
                        .position(node.position)
                }
            }
            .scaleEffect(scale * gestureScale)
            .offset(x: offset.width + gestureTranslation.width,
                    y: offset.height + gestureTranslation.height)
            .contentShape(Rectangle())      // make entire area hit‑testable
            //.gesture(combined)
            .onChange(of: geo.size) { _, newSize in
                print("Width: \(newSize.width), Height: \(newSize.height)")
            }
        }
    }
}

//struct GraphView: View {
//    @State var store: GraphStore
//
//    // Pan & zoom state
//    @State private var scale: CGFloat = 1.0
//    @State private var offset: CGSize = .zero
//
//    @GestureState private var gestureScale: CGFloat = 1.0
//    @GestureState private var gestureTranslation: CGSize = .zero
//    
//    let minScale: CGFloat = 0.25   // 25 % of original size
//    let maxScale: CGFloat = 4.0    // 400 %
//
//    var body: some View {
//        // --- Compute world‑space extremes (centres only) ---
//        let xs = store.nodesByID.values.map { $0.position.x }
//        let ys = store.nodesByID.values.map { $0.position.y }
//        let minWorldX = xs.min() ?? 0
//        let maxWorldX = xs.max() ?? 0
//        let minWorldY = ys.min() ?? 0
//        let maxWorldY = ys.max() ?? 0
//        let margin: CGFloat = 10
//        
//        GeometryReader { geo in
//            
//            let dragGesture = DragGesture()
//                .updating($gestureTranslation) { value, state, _ in
//                    state = value.translation
//                }
//                .onEnded { value in
//                    let newOffsetWidth  = offset.width  + value.translation.width
//                    let newOffsetHeight = offset.height + value.translation.height
//                    
//                    // Re‑compute scaled bounds with the *current* scale
//                    let scaledMinX = minWorldX * scale
//                    let scaledMaxX = maxWorldX * scale
//                    let scaledMinY = minWorldY * scale
//                    let scaledMaxY = maxWorldY * scale
//                    
//                    let minOffsetX = (geo.size.width  - margin) - scaledMaxX
//                    let maxOffsetX = margin - scaledMinX
//                    let minOffsetY = (geo.size.height - margin) - scaledMaxY
//                    let maxOffsetY = margin - scaledMinY
//                    
//                    print("Min offset X: \(minOffsetX) and max : \(maxOffsetX)")
//                    
//                    withAnimation(.spring) {
//                        offset.width  = newOffsetWidth
//                        offset.height = newOffsetHeight.clamped(to: minWorldY...maxWorldY)
//                    }
//                }
//
////            let magnificationGesture = MagnificationGesture()
////                .updating($gestureScale) { value, state, _ in
////                    state = value
////                }
////                .onEnded { value in
////                    // Clamp scale first
////                    let newScale = (scale * value).clamped(to: minScale...maxScale)
////                    scale = newScale
////
////                    // Re‑compute scaled bounds with *new* scale and clamp offset
////                    let scaledMinX = minWorldX * newScale
////                    let scaledMaxX = maxWorldX * newScale
////                    let scaledMinY = minWorldY * newScale
////                    let scaledMaxY = maxWorldY * newScale
////
////                    let minOffsetX = (geo.size.width  - margin) - scaledMaxX
////                    let maxOffsetX = margin - scaledMinX
////                    let minOffsetY = (geo.size.height - margin) - scaledMaxY
////                    let maxOffsetY = margin - scaledMinY
////
////                    withAnimation(.spring) {
////                        offset.width  = offset.width
////                        offset.height = offset.height
////                    }
////                }
////
////            let combined = dragGesture.simultaneously(with: magnificationGesture)
//            
//            ZStack {
//                // Edges layer
//                Canvas { context, _ in
//                    for edge in store.edges {
//                        guard
//                            let a = store.nodesByID[edge.sourceID]?.position,
//                            let b = store.nodesByID[edge.targetID]?.position
//                        else { continue }
//                        
//                        var path = Path()
//                        path.move(to: a)
//                        path.addLine(to: b)
//                        
//                        context.stroke(
//                            path,
//                            with: .color(.primary.opacity(0.5)),
//                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
//                        )
//                    }
//                }
//
//                // Nodes layer
//                ForEach(store.nodesByID.values.sorted(by: { $0.id.uuidString < $1.id.uuidString })) { node in
//                    NodeView(node: node)
//                        .position(node.position)
//                }
//            }
//            .scaleEffect(scale * gestureScale)
//            .offset(x: offset.width + gestureTranslation.width,
//                    y: offset.height + gestureTranslation.height)
//            .contentShape(Rectangle())      // make entire area hit‑testable
//            //.gesture(combined)
//            .onChange(of: geo.size) { _, newSize in
//                print("Width: \(newSize.width), Height: \(newSize.height)")
//            }
//        }
//    }
//}

// MARK: - NodeView helper

struct NodeView: View {
    var node: Node

    var body: some View {
        Group {
            switch node.shape {
            case .circle:
                Circle().fill(.blue)
            case .square:
                Rectangle().fill(.orange)
            }
        }
        .frame(width: node.size, height: node.size)
        .overlay(
            Group {
                switch node.shape {
                case .circle:
                    Circle().strokeBorder(.white, lineWidth: 2)
                case .square:
                    Rectangle().strokeBorder(.white, lineWidth: 2)
                }
            }
        )
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

#Preview {
    GraphView(store: .sample())
}
