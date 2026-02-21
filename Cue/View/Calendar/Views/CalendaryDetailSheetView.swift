//
//  CalendaryDetailSheetView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 05/02/2026.
//

import SwiftUI
import Model
import VanorUI

public struct CalendaryDetailSheetView: View {
    
    let calendarDay: CalendarDay
    let presentCreateReminder: () -> Void
    
    public init(calendarDay: CalendarDay, presentCreateReminder: @escaping () -> Void) {
        self.calendarDay = calendarDay
        self.presentCreateReminder = presentCreateReminder
    }
    
    public var body: some View {
        VStack(alignment: .center, spacing: 16) {
            DateView(todayModel: .init(date: calendarDay.date, mode: .noArc))
                .padding(.bottom, 8)
            if calendarDay.reminders.isEmpty {
                VStack(alignment: .center, spacing: 8) {
                    Text("😇")
                        .font(.system(.largeTitle))
                    
                    Text("You have nothing cue-ed in for today!")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Button (action: presentCreateReminder) {
                        Text("Add an reminder")
                            .font(.headline)
                            .padding(.init(top: 8, leading: 12, bottom: 8, trailing: 12))
                    }
                    .tint(Color.proSky.baseColor)
                    .buttonStyle(.glassProminent)
                    .padding(.top, 8)

                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            if !calendarDay.loggedReminders.isEmpty {
                Section {
                    ForEach(calendarDay.loggedReminders, id: \.hashValue) { loggedReminder in
                        ReminderView(model: .init(title: loggedReminder.reminder.title,
                                                  icon: iconForCueIcon(loggedReminder.reminder.icon),
                                                  theme: Color.proSky,
                                                  time: loggedReminder.reminder.date,
                                                  state: .calendarDetailView(true),
                                                  tags: loggedReminder.reminder.tags.map { .init(name: $0.name, color: $0.color) }, logReminder: nil,
                                                  deleteReminder: nil))
                        .padding(.bottom, 4)
                        .id("logged-\(loggedReminder.hashValue)")
                    }
                } header: {
                    Label("Logged", systemSymbol: .checkmarkSeal)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.bottom, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            if !notLoggedReminder.isEmpty {
                Section {
                    ForEach(notLoggedReminder, id: \.hashValue) { reminder in
                        ReminderView(model: .init(title: reminder.title,
                                                  icon: iconForCueIcon(reminder.icon),
                                                  theme: Color.proSky,
                                                  time: reminder.date,
                                                  state: .calendarDetailView(false),
                                                  tags: reminder.tags.map { .init(name: $0.name, color: $0.color) },
                                                  logReminder: nil,
                                                  deleteReminder: nil))
                        .padding(.bottom, 4)
                        .id("notLogged-\(reminder.hashValue)")
                    }
                } header: {
                    Label("Planned", systemSymbol: .calendar)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.bottom, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.init(top: 16, leading: 20, bottom: 16, trailing: 20))
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    
    // MARK: - Helpers
    
    func iconForCueIcon(_ cueIcon: CueIcon) -> Icon {
        if let emoji = cueIcon.emoji {
            return .emoji(.init(emoji))
        } else if let symbol = cueIcon.symbol {
            return .symbol(.init(rawValue: symbol))
        } else {
            fatalError("Must have a icon")
        }
    }
    
    var notLoggedReminder: [ReminderModel] {
        return calendarDay.reminders.filter { reminder in
           !calendarDay.loggedReminders.contains { $0.reminder == reminder }
        }
    }

}
