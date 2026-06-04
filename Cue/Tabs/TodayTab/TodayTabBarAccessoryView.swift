//
//  TodayTabBarAccessoryView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 17/05/2026.
//

import VanorUI
import SwiftUI
import Combine

struct TodayTabBarAccessoryView: View {
    
    let isToday: Bool
    let todayPublisher: PassthroughSubject<Void, Never>
    
    var body: some View {
        Group {
            if !isToday {
                Button {
                    // Do soemthing
                    todayPublisher.send(())
                } label: {
                    Text("today")
                        .font(.bitcountMedium(style: .headline))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .containerShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                HStack(alignment: .center, spacing: 4) {
                    Text("Tasks")
                        .font(.headline)
                    TimeCompactSwiftUIView(model: .init(elements: []), date: .now)
                        .padding(.horizontal, 20)
                }
            }
        }
        .padding(.all, 16)
    }
    
}
