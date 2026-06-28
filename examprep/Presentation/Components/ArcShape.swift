//
//  ArcShape.swift
//  isaprep
//
//  Created by user on 27/3/2025.
//

import SwiftUI

struct ArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.maxY),
                    radius: rect.width / 2,
                    startAngle: .degrees(180),
                    endAngle: .degrees(0),
                    clockwise: false)
        return path
    }
}

#Preview {
    ZStack {
        // Background arc (gray)
        ArcShape()
            .stroke(Color.gray.opacity(0.3), lineWidth: 14)
        
        // Progress arc (accent)
        ArcShape()
            .trim(from: 0, to: 0.7) // Trim to show progress
            .stroke(theme.accent, style: StrokeStyle(lineWidth: 14, lineCap: .round))
    }
    .frame(width: 150, height: 75)
}
