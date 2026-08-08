//
//  FocusCountdownShape.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/08/2026.
//

import SwiftUI
import VanorUI

#warning("Use the `VanorUI`, it is currently internal")
internal struct FocusCountdownShape: Shape {
    
    var pct: CGFloat
    let lineWidth: CGFloat
    
    var animatableData: CGFloat {
        get { pct }
        set { pct = newValue }
    }
    
    nonisolated func path(in rect: CGRect) -> Path {
        let radius = (rect.size.smallDim - lineWidth).half
        return Path { path in
            path.addArc(center: rect.center, radius: radius, startAngle: .degrees(0), endAngle: .degrees(360 * Double(1 - pct)), clockwise: false)
        }
        .strokedPath(.init(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
    }
}
