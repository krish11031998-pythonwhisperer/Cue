//
//  WelcomeOnboardingView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/02/2026.
//

import SwiftUI
import VanorUI

struct WelcomeOnboardingView: View {

    let getStarted: () -> Void

    var body: some View {
        OnboardingStepLayout(includeScrollView: false) {
            OnboardingHeader(title: Text("Create impactful reminders").foregroundStyle(OnboardingPalette.skyInk),
                             subtitle: "and plan out your day effectively",
                             alignment: .center)
                .padding(.horizontal, 8)
        } content: {
            VStack(alignment: .center, spacing: -6) {
                ForEach(WelcomeItemComponents.cases.enumerated(), id: \.element) { itemContent in
                    WelcomeFeatureItemView(cardCorner: itemContent.offset % 2 == 0 ? .leading : .trailing, component: itemContent.element)
                        .zIndex(Double(itemContent.offset))
                        .dynamicTypeSize(..<DynamicTypeSize.large)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
//        actions: {
//            Button("Get started", action: getStarted)
//                .buttonStyle(.onboardingPrimary)
//
//            Text("cue:ai requires cue:it Pro and a device that supports Apple Intelligence.")
//                .font(.caption2)
//                .foregroundStyle(.secondary)
//                .multilineTextAlignment(.center)
//        }
    }
}


#Preview {
    WelcomeOnboardingView {}
        .background(Color.cueItBackground)
}
