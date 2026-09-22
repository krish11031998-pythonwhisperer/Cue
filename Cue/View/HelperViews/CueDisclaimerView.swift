//
//  CueDisclaimerView.swift
//  Kyu
//
//  Created by Krishna Venkatramani on 22/09/2026.
//

import Foundation
import SwiftUI
import VanorUI

public enum CueDisclaimer {
    case cueAIRunsOnDevice
    
    var message: String {
        switch self {
        case .cueAIRunsOnDevice:
            return "cue:ai runs entirely on this device using Apple Intelligence. Your voice and what you type are never sent to us or to any third-party AI service."
        }
    }
    
    var icon: SFSymbol {
        switch self {
        case .cueAIRunsOnDevice:
            return .lockIphone
        }
    }
}

public enum CueDisclaimerType {
    case persistent
    case temporary(TimeInterval)
}


struct CueDisclaimerView: View {
    let disclaimer: CueDisclaimer
    
    init(disclaimer: CueDisclaimer) {
        self.disclaimer = disclaimer
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemSymbol: disclaimer.icon)
                .font(.headline)
                .foregroundStyle(Color.proSky.baseColor)
            
            Text(disclaimer.message)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.init(top: 14, leading: 14, bottom: 14, trailing: 14))
        .glassEffect(.regular, in: .roundedRect(cornerRadius: 16))
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
    }
}


struct CueDisclaimerViewModifier: ViewModifier {

    let disclaimer: CueDisclaimer
    let disclaimerType: CueDisclaimerType
    let startDate: Date
    
    init(disclaimer: CueDisclaimer, disclaimerType: CueDisclaimerType) {
        self.disclaimer = disclaimer
        self.disclaimerType = disclaimerType
        self.startDate = .now
    }
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top , alignment: .center, spacing: 0) {
                switch disclaimerType {
                case .persistent:
                    CueDisclaimerView(disclaimer: disclaimer)
                case .temporary(let duration):
                    TimelineView(.animation) { context in
                        let timeElapsed = context.date.timeIntervalSince(startDate)
                        
                        if timeElapsed <= duration {
                            CueDisclaimerView(disclaimer: disclaimer)
                                .transition(.popIn().animation(.easeInOut))
                        } else {
                            EmptyView()
                        }
                    }
                }
            }
    }
}

public extension View {
    func disclaimer(_ disclaimer: CueDisclaimer, type: CueDisclaimerType) -> some View {
        self.modifier(CueDisclaimerViewModifier(disclaimer: disclaimer, disclaimerType: type))
    }
}
