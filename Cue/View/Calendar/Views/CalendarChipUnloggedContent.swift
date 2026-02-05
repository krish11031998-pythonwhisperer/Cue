//
//  CalendarChipUnloggedContent.swift
//  Cue
//
//  Created by Krishna Venkatramani on 05/02/2026.
//

import SwiftUI
import VanorUI


public struct CalendarChipUnloggedContent: View {
    
    let count: Int
    
    public var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Spacer()
            if count - 3 > 0 {
                Text("+\(count - 3)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.proSky.foregroundPrimary)
                    .padding(.bottom, 2)
            }
            ForEach(0..<min(3, count), id: \.self) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .foregroundStyle(Color.proSky.baseColor)
                    .frame(height: 4, alignment: .center)
            }
        }
    }
    
}
