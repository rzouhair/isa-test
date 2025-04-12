//
//  ResizableCropFrameView.swift
//  notescan
//
//  Created by user on 1/4/2025.
//

import SwiftUI

struct ResizableCropFrameView: View {
    @Binding var cropRect: CGRect
    let parentSize: CGSize

    private let minSize: CGFloat = 50 // Minimum size of the crop area
    private let cornerMarkerSize: CGFloat = 20 // Size of corner markers
    private let cornerMarkerThickness: CGFloat = 4 // Thickness of corner markers
    
    // Track initial positions for gestures
    @GestureState private var isDragging: Bool = false
    @GestureState private var isResizing: Bool = false
    @State private var lastDragPosition: CGPoint?
    @State private var initialRect: CGRect = .zero

    var body: some View {
        ZStack {
            // Semi-transparent overlay outside crop area
            Rectangle()
                .fill(Color.black.opacity(0.3))
                .frame(width: parentSize.width, height: parentSize.height)
                .mask(
                    Rectangle()
                        .frame(width: parentSize.width, height: parentSize.height)
                        .overlay(
                            Rectangle()
                                .frame(width: cropRect.width, height: cropRect.height)
                                .position(x: cropRect.midX, y: cropRect.midY)
                                .blendMode(.destinationOut)
                        )
                )
            
            // Crop Frame Border
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: cropRect.width, height: cropRect.height)
                .position(x: cropRect.midX, y: cropRect.midY)
                .gesture(dragGesture)

            // Corner Markers (L-shaped)
            ForEach(Corner.allCases, id: \.self) { corner in
                CornerMarker(corner: corner, size: cornerMarkerSize, thickness: cornerMarkerThickness)
                    .foregroundColor(Color.white)
                    .position(handlePosition(for: corner))
                    .gesture(resizeGesture(for: corner))
            }
        }
    }

    // MARK: - Dragging Gesture
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if lastDragPosition == nil {
                    lastDragPosition = value.startLocation
                    initialRect = cropRect
                }
                
                guard let lastPosition = lastDragPosition else { return }
                
                let translationX = value.location.x - lastPosition.x
                let translationY = value.location.y - lastPosition.y
                
                var newOrigin = initialRect.origin
                newOrigin.x += translationX
                newOrigin.y += translationY
                
                // Constrain to bounds
                newOrigin.x = max(0, min(newOrigin.x, parentSize.width - cropRect.width))
                newOrigin.y = max(0, min(newOrigin.y, parentSize.height - cropRect.height))
                
                cropRect.origin = newOrigin
            }
            .onEnded { _ in
                lastDragPosition = nil
            }
            .updating($isDragging) { _, state, _ in
                state = true
            }
    }

    // MARK: - Resize Gesture
    private func resizeGesture(for corner: Corner) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if lastDragPosition == nil {
                    lastDragPosition = value.startLocation
                    initialRect = cropRect
                }
                
                guard let lastPosition = lastDragPosition else { return }
                
                let translationX = value.location.x - lastPosition.x
                let translationY = value.location.y - lastPosition.y
                
                // Create a copy to work with
                var newRect = initialRect
                
                // Apply changes based on corner being dragged
                switch corner {
                case .topLeft:
                    // Update top-left position
                    newRect.origin.x += translationX
                    newRect.origin.y += translationY
                    // Adjust size accordingly
                    newRect.size.width -= translationX
                    newRect.size.height -= translationY
                    
                case .topRight:
                    // Update top position
                    newRect.origin.y += translationY
                    // Adjust size
                    newRect.size.width += translationX
                    newRect.size.height -= translationY
                    
                case .bottomLeft:
                    // Update left position
                    newRect.origin.x += translationX
                    // Adjust size
                    newRect.size.width -= translationX
                    newRect.size.height += translationY
                    
                case .bottomRight:
                    // Just adjust size for bottom-right
                    newRect.size.width += translationX
                    newRect.size.height += translationY
                }
                
                // Apply constraints: minimum size
                if newRect.size.width < minSize {
                    switch corner {
                    case .topLeft, .bottomLeft:
                        newRect.origin.x = initialRect.origin.x + initialRect.size.width - minSize
                    default:
                        break
                    }
                    newRect.size.width = minSize
                }
                
                if newRect.size.height < minSize {
                    switch corner {
                    case .topLeft, .topRight:
                        newRect.origin.y = initialRect.origin.y + initialRect.size.height - minSize
                    default:
                        break
                    }
                    newRect.size.height = minSize
                }
                
                // Constrain to parent bounds
                if newRect.origin.x < 0 {
                    let diff = -newRect.origin.x
                    newRect.origin.x = 0
                    newRect.size.width -= diff
                }
                
                if newRect.origin.y < 0 {
                    let diff = -newRect.origin.y
                    newRect.origin.y = 0
                    newRect.size.height -= diff
                }
                
                if newRect.origin.x + newRect.size.width > parentSize.width {
                    newRect.size.width = parentSize.width - newRect.origin.x
                }
                
                if newRect.origin.y + newRect.size.height > parentSize.height {
                    newRect.size.height = parentSize.height - newRect.origin.y
                }
                
                // Ensure we still meet minimum size
                newRect.size.width = max(minSize, newRect.size.width)
                newRect.size.height = max(minSize, newRect.size.height)
                
                // Apply the constrained rectangle
                cropRect = newRect
            }
            .onEnded { _ in
                lastDragPosition = nil
            }
            .updating($isResizing) { _, state, _ in
                state = true
            }
    }

    // MARK: - Handle Positions
    private func handlePosition(for corner: Corner) -> CGPoint {
        switch corner {
        case .topLeft:
            return CGPoint(x: cropRect.minX, y: cropRect.minY)
        case .topRight:
            return CGPoint(x: cropRect.maxX, y: cropRect.minY)
        case .bottomLeft:
            return CGPoint(x: cropRect.minX, y: cropRect.maxY)
        case .bottomRight:
            return CGPoint(x: cropRect.maxX, y: cropRect.maxY)
        }
    }

    // MARK: - Corners Enum
    enum Corner: CaseIterable {
        case topLeft, topRight, bottomLeft, bottomRight
    }
}

// MARK: - L-shaped Corner Marker
struct CornerMarker: View {
    let corner: ResizableCropFrameView.Corner
    let size: CGFloat
    let thickness: CGFloat
    
    var body: some View {
        ZStack {
            // Horizontal line
            Rectangle()
                .frame(width: size, height: thickness)
                .offset(x: horizontalOffset, y: 0)
            
            // Vertical line
            Rectangle()
                .frame(width: thickness, height: size)
                .offset(x: 0, y: verticalOffset)
        }
    }
    
    private var horizontalOffset: CGFloat {
        switch corner {
        case .topLeft, .bottomLeft:
            return size / 2
        case .topRight, .bottomRight:
            return -size / 2
        }
    }
    
    private var verticalOffset: CGFloat {
        switch corner {
        case .topLeft, .topRight:
            return size / 2
        case .bottomLeft, .bottomRight:
            return -size / 2
        }
    }
}
