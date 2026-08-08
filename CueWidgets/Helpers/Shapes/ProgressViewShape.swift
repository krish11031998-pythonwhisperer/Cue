//
//  ProgressViewShape.swift
//  Cue
//
//  Created by Krishna Venkatramani on 08/08/2026.
//

import SwiftUI

struct ProgressViewShape: Shape {
    
    var pct: CGFloat
    
    var animatableData: CGFloat {
        get { pct }
        set { pct = newValue }
    }
    
    nonisolated func path(in rect: CGRect) -> Path {
        Path { path in
            let smallDim = min(rect.width, rect.height)
            let cornerRadiusSize: CGSize = .init(width: smallDim * 0.5, height: smallDim * 0.5)
            path.addRoundedRect(in: .init(origin: rect.origin, size: .init(width: rect.width * pct, height: rect.height)), cornerSize: cornerRadiusSize)
        }
    }
}
