//
//  CalendarDayView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 27/01/2026.
//

import SwiftUI
import VanorUI
import Model

internal struct TimeCompactViewTopPaddingEnvironmentKey: @MainActor EnvironmentKey {
    @MainActor static var defaultValue: CGFloat = 0
}

public extension EnvironmentValues {
    @MainActor
    var timeCompactViewTopPadding: CGFloat {
        get {
            self[TimeCompactViewTopPaddingEnvironmentKey.self]
        } set {
            self[TimeCompactViewTopPaddingEnvironmentKey.self] = newValue
        }
    }
}

public struct CalendarDayView: View {
    
    enum Presentation: Int, Identifiable {
        case addReminder = 0
        
        var id: Int { rawValue }
    }
    
    private let store: Store
    @State private var presentation: Presentation? = nil
    @State private var viewModel: CalendarDayViewModel
    @Environment(\.timeCompactViewTopPadding) var topPadding
    init (store: Store, calendarDay: CalendarDay) {
        self.store = store
        self._viewModel = .init(initialValue: .init(calendarDay: calendarDay))
    }
    
    
    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                DateView(todayModel: .init(date: viewModel.calendarDay.date, reminderCompleted: .random(in: 1...5), reminderTotal: 5))
                    .padding(.bottom, 32)
                if viewModel.calendarDay.reminders.isEmpty {
                    ContentUnavailableView("You have no scheduled Reminders or Habits for today.",
                                           systemSymbol: .squareSlash)
                        .font(.headline)
                } else {
                    ForEach(viewModel.calendarDay.reminders.indices, id: \.self) { index in
                        let reminder = viewModel.calendarDay.reminders[index]
                        reminderBuilder(reminder)
                            .padding(.bottom, 8)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
    }
    
    
    private var descriptionText: Text {
        Text("Add Reminders to start organizing your day.")
            .font(.caption)
            .foregroundColor(.foregroundSecondary)
    }
    
    
    private func reminderBuilder(_ reminder: Reminder) -> some View {
        let tasks: [ReminderView.TaskModel] = reminder.tasksContainer.tasks.map {
            let icon: Icon
            switch $0.icon {
            case .emoji(let emoji):
                icon = .emoji(.init(emoji))
            case .symbol(let symbol):
                icon = .symbol(.init(rawValue: symbol))
            default:
                icon = .symbol(.circle)
            }
            return .init(title: $0.title, icon: icon)
        }
        let isExpanded = !tasks.isEmpty && viewModel.expandedReminder.contains(reminder)
        
        let icon: VanorUI.Icon
        if let symbol = reminder.icon.symbol {
            icon = .symbol(.init(rawValue: symbol))
        } else if let emoji = reminder.icon.emoji {
            icon = .emoji(.init(emoji))
        } else {
            icon = .symbol(.circle)
        }
        
        let model: ReminderView.Model = .init(title: reminder.title,
                                              icon: icon,
                                              theme: Color.proSky,
                                              time: reminder.date,
                                              state: .hasLogged(.init(hasLogged: false)),
                                              showTask: isExpanded,
                                              tasks: tasks) { [weak viewModel] in
            viewModel?.logReminder(reminder)
        } expandReminder: { [weak viewModel] in
            withAnimation(.snappy) {
                viewModel?.expandReminder(reminder)
            }
        }
        
        return ReminderView(model: model)
    }
}
