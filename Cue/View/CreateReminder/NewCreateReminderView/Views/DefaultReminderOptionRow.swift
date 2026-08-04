//
//  ReminderOptionActionField.swift
//  Cue
//
//  Created by Krishna Venkatramani on 26/07/2026.
//

import SwiftUI
import VanorUI


// MARK: - Reminder Options


enum ReminderOptionActionField: Identifiable {
    case button(ActionButtonListRow.Config)
    case toggle(ActionToggleListRow.Config)
    
    var id: String {
        switch self {
        case .button(let config):
            config.id
        case .toggle(let config):
            config.id
        }
    }
}

struct ReminderOptionConfig: Identifiable {
    let title: String
    let actions: [ReminderOptionActionField]
    
    var id: Int {
        var hasher = Hasher()
        actions.forEach { action in
            let id: String = action.id
            hasher.combine(id)
        }
        return hasher.finalize()
    }
    
    init(title: String, actions: [ReminderOptionActionField]) {
        self.title = title
        self.actions = actions
    }
}

struct ReminderOptionRow<PrimaryContent: View, InnerContent: View>: View {
    
    private let verticalPadding: CGFloat = 12
    private let horizontalPadding: CGFloat = 16
    
    let title: String
    @ViewBuilder var primaryContent: () -> PrimaryContent
    @ViewBuilder var innerContent: () -> InnerContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: horizontalPadding) {
                Text(title)
                    .font(.body)
                
                primaryContent()
            }
            
            innerContent()
                .padding(.top, verticalPadding)
        }
        .padding(.init(top: verticalPadding, leading: horizontalPadding, bottom: verticalPadding, trailing: horizontalPadding))
        .modifier(RowBackground())
    }
    
}

struct DefaultReminderOptionRow<InnerContent: View>: View {
    let config: ReminderOptionConfig
    @ViewBuilder let innerContent: () -> InnerContent
    
    var body: some View {
        ReminderOptionRow(title: config.title) {
            ForEach(config.actions) { action in
                Group {
                    switch action {
                    case .button(let config):
                        ActionButtonListRow(config: config)
                    case .toggle(let config):
                        ActionToggleListRow(config: config)
                    }
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .minimumScaleFactor(0.8)
            }
        } innerContent: {
            innerContent()
        }
    }
}

extension DefaultReminderOptionRow where InnerContent == EmptyView {
    init(config: ReminderOptionConfig) {
        self.config = config
        self.innerContent = { EmptyView() }
    }
}


#Preview {
    DefaultReminderOptionRow(config: .init(title: "Date", actions: [.button(.init(symbol: .calendar, label: "Today", action: { }))]))
}
