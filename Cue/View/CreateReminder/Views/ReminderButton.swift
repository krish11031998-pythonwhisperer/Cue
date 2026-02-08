//
//  ReminderButton.swift
//  Cue
//
//  Created by Krishna Venkatramani on 08/02/2026.
//

import SwiftUI
import VanorUI

struct ReminderButton: View {
    
    let presentation: CreateReminderViewModel.ReminderCalendarPresentation
    let buttonTitle: String
    var animation: Namespace.ID
    let action: (CreateReminderViewModel.ReminderCalendarPresentation) -> Void
    
    var body: some View {
        Button {
            action(presentation)
        } label: {
            Label {
                Text(buttonTitle)
            } icon: {
                Image(systemSymbol: symbol)
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .padding(.init(top: 6, leading: 8, bottom: 6, trailing: 8))
            .background(Color.backgroundSecondary, in: .capsule)
        }
        .buttonStyle(.plain)
        .matchedTransitionSource(id: presentation,
                                 in: animation)
    }
    
    
    // MARK:  Symbol
    
    var symbol: SFSymbol {
        switch presentation {
        case .alarmAt:
            return .alarm
        case .duration:
            return .zzz
        case .date:
            return .calendar
        case .repeat:
            return .arrow2Squarepath
        case .symbolAndColor:
            fatalError("\(presentation.rawValue) has no symbol")
        }
    }
}
