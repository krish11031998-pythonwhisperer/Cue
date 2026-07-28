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
    @State private var presentation: Presentation? = nil
    @State private var addReminder: Bool = false
    @State private var viewModel: CalendarDayViewModel
    @Environment(\.screenPadding) var screenPadding
    
    init (store: Store, calendarDay: CalendarDay) {
        self._viewModel = .init(initialValue: .init(calendarDate: calendarDay.date, store: store))
        self.store = store
        self.calendarDay = calendarDay
    }
    
    var date: Date {
        calendarDay.date
    }
    
    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
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
            .scrollEdgeEffectStyle(.soft, for: .all)
        }
        .task(id: calendarDay) {
            self.viewModel.sections(calendarDay: calendarDay)
            self.viewModel.loggedReminders(calendarDay.loggedReminders)
        }
        .sheet(item: $presentation, content: { presentation in
            switch presentation {
            case .editReminder(let model):
                NavigationView {
                    #if NEW_CREATE_REMINDER
                    NewCreateReminderView(mode: .edit(model), store: store)
                    #else
                    CreateReminderView(mode: .edit(model), store: store)
                    #endif
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
                    Group {
                        if calendarDay.date.startOfDay < Date.now.startOfDay {
                            Text("no past reminders in cue.")
                        } else {
                            Text("there is nothing in the cue yet.")
                        }
                    }
                    .font(.bitcountRegular(style: .title3))
                }
            }
        }
        .scrollEdgeEffectStyle(.soft, for: .all)
        .ignoresSafeArea(.container, edges: .all)
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
                Text(section.title.lowercased())
                    .font(hasTasks ? .bitcountMedium(style: .title3) : .bitcountRegular(style: .title3))
                Image(systemSymbol: .chevronDown)
                    .font(.caption2)
            }
        }
    }
}

extension CalendarDayView: PageContentView {
    
    struct Model: Hashable {
        let store: Store
        let calendarDay: CalendarDay
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(calendarDay)
        }
        
        static func ==(lhs: Model, rhs: Model) -> Bool {
            lhs.calendarDay == rhs.calendarDay
        }
    }
    
    init(model: Model) {
        self.init(store: model.store, calendarDay: model.calendarDay)
    }
    
}
