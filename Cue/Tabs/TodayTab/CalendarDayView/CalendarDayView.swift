//
//  CalendarDayView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 27/01/2026.
//

import SwiftUI
import VanorUI
import Model

struct ScreenVerticalPadding {
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    
    static func zero() -> Self {
        return .init(topPadding: 0, bottomPadding: 0)
    }
}

internal struct TimeCompactViewTopPaddingEnvironmentKey: @MainActor EnvironmentKey {
    @MainActor static var defaultValue: ScreenVerticalPadding = .zero()
}

extension EnvironmentValues {
    @MainActor
    var screenPadding: ScreenVerticalPadding {
        get {
            self[TimeCompactViewTopPaddingEnvironmentKey.self]
        } set {
            self[TimeCompactViewTopPaddingEnvironmentKey.self] = newValue
        }
    }
}

public struct CalendarDayView: View {
    
    enum Presentation: Identifiable {
        case editReminder(ReminderModel)
        
        var id: Int {
            switch self {
            case .editReminder(let reminderModel):
                return reminderModel.hashValue
            }
        }
    }
    
    private let store: Store
    private let calendarDay: CalendarDay
    private var presentCreateReminder: () -> Void
    @State private var presentation: Presentation? = nil
    @State private var addReminder: Bool = false
    @State private var viewModel: CalendarDayViewModel
    @Environment(\.screenPadding) var screenPadding
    
    init (store: Store, calendarDay: CalendarDay, presentCreateReminder: @escaping () -> Void) {
        self._viewModel = .init(initialValue: .init(calendarDate: calendarDay.date, store: store))
        self.store = store
        self.calendarDay = calendarDay
        self.presentCreateReminder = presentCreateReminder
    }
    
    var date: Date {
        calendarDay.date
    }
    
    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
//                DateView(todayModel: .init(date: date,
//                                           mode: date.isToday ? .arc(viewModel.timelineElements) : .noArc))
//                    .padding(.bottom, 32)
                VStack(alignment: .center, spacing: 4) {
                    Text(Calendar.current.weekdaySymbols[date.weekDayValue - 1].lowercased())
                        .font(.bitcountMedium(style: .extraLargeTitle))
                    Text(date.headerDateStringFormatter())
                        .font(.subheadline)
                }
                .padding(.bottom, 10)
                .padding(.top, 10)
                .frame(maxWidth: .infinity, alignment: .center)
                
                if !calendarDay.reminders.isEmpty {
                    ForEach(viewModel.sections) { section in
                        Section {
                            ForEach(section.reminders) { model in
                                Button {
                                    self.presentation = .editReminder(model.reminder)
                                } label: {
                                    ReminderView(model: model.viewConfig)
                                        .id(model)
                                        .padding(.bottom, 10)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            SectionHeader(section: section.timeOfDay, hasTasks: !section.reminders.isEmpty)
                                .padding(.bottom, 8)
                        } footer: {
                            Color.clear
                                .frame(height: 14, alignment: .center)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, screenPadding.topPadding)
            .padding(.bottom, screenPadding.bottomPadding)
        }
        .task(id: calendarDay) {
            self.viewModel.sections(calendarDay: calendarDay)
            self.viewModel.loggedReminders(calendarDay.loggedReminders)
        }
        .scrollEdgeEffectStyle(.soft, for: .all)
        .sheet(item: $presentation, content: { presentation in
            switch presentation {
            case .editReminder(let model):
                NavigationView {
                    CreateReminderView(mode: .edit(model), store: store)
                }
                .presentationDetents([.fraction(1)])
            }
        })
        .overlay(alignment: .center) {
            if calendarDay.reminders.isEmpty {
                ContentUnavailableView {
                    #if KARINA_TESTING
                    #else
                    Image(systemSymbol: .squareSlash)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120, alignment: .center)
                    #endif
                } description: {
                    Text("there is nothing in the cue yet.")
                        .font(.bitcountRegular(style: .title3))
//                        .font(.title3)
//                        .fontWeight(.semibold)
//                        .padding(.top, 12)
                } actions: {
                    #if !KARINA_TESTING
                    Button {
                        self.presentCreateReminder()
                    } label: {
                        Text("Add a reminder")
                            .font(.headline)
                            .padding(.init(top: 8, leading: 12, bottom: 8, trailing: 12))
                            .font(.headline)
                    }
                    .buttonStyle(.glass)
                    #endif
                }
            }
        }
    }
    
    
    private var descriptionText: Text {
        Text("Add Reminders to start organizing your day.")
            .font(.caption)
            .foregroundColor(.foregroundSecondary)
    }
    
    
    // MARK: - SectionHeader
    
    #warning("Move this to VanorUI")
    struct SectionHeader: View {
        
        let section: CalendarDayViewModel.TimeOfDay
        let hasTasks: Bool
        
        var body: some View {
            HStack(alignment: .center, spacing: 4) {
//                Image(systemSymbol: section.symbol)
                Text(section.title.lowercased())
                    .font(hasTasks ? .bitcountMedium(style: .title3) : .bitcountRegular(style: .title3))
                Image(systemSymbol: .chevronDown)
                    .font(.caption2)
            }
//            .font(.footnote)
//            .fontWeight(.medium)
//            .padding(.init(top: 6, leading: 12, bottom: 6, trailing: 12))
//            .background(section.color.surfacePrimary, in: .capsule)
        }
    }
}
//
