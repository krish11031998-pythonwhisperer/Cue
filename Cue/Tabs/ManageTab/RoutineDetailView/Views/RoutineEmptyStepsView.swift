//
//  RoutineEmptyView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 27/09/2026.
//

import SwiftUI
import VanorUI

struct RoutineEmptyStepsView: View {
    @Environment(\.theme) var theme
    
    var attributedString: AttributedString {
        var firstMessage = AttributedString("Add some tasks relevant to your routine, or use  ")
        firstMessage.font = .body
        firstMessage.foregroundColor = theme.foregroundPrimary
        
        var cueAIMessage = AttributedString("cue:ai")
        cueAIMessage.font = .bitcountRegular(style: .body)
        cueAIMessage.foregroundColor = theme.foregroundTertiary
        
        var remainingMessage = AttributedString(" to suggest some relevant tasks")
        remainingMessage.font = .body
        remainingMessage.foregroundColor = theme.foregroundPrimary
        
        return firstMessage + cueAIMessage + remainingMessage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label {
                Text("Add Subtasks")
            } icon: {
                Image(systemSymbol: .plus)
            }
            .font(.headline)
            .foregroundStyle(theme.foregroundPrimary)
            
            Text(attributedString)
        }
        .padding(.all, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .center) {
            RoundedRectangle(cornerRadius: 32)
                .fill(theme.backgroundPrimary)
                .stroke(theme.outlinePrimary, style: .init(lineWidth: 1, lineCap: .round, lineJoin: .round, dash: [2, 5], dashPhase: 0.4))
        }
    }
}
