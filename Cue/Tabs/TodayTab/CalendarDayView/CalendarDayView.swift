//
//  CalendarDayView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 27/01/2026.
//

import SwiftUI
import VanorUI
import Model
import Combine

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
    /// Refreshed on the minute so the day rail, the "now" stretch and each card's
    /// countdown stay honest while the page is open.
    @State private var now: Date = .now
    @State private var collapsedSegments: Set<CalendarDayViewModel.TimeOfDay> = []
    @Environment(\.screenPadding) var screenPadding
    
    private let minuteTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
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
                DayProgressHeaderView(date: date,
                                      now: now,
                                      completedCount: viewModel.completedCount,
                                      totalCount: viewModel.totalCount)
                .padding(.top, 10)
                .padding(.bottom, 20)
                
                if !calendarDay.reminders.isEmpty {
                    ForEach(viewModel.sections) { section in
                        Section {
                            if !isCollapsed(section.timeOfDay) {
                                sectionContent(section)
                            }
                        } header: {
                            sectionHeader(section)
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
        .onReceive(minuteTimer) { date in
            withAnimation(.easeInOut) {
                self.now = date
            }
        }
        .sheet(item: $presentation, content: { presentation in
            switch presentation {
            case .editReminder(let model):
                NavigationView {
                    NewCreateReminderView(mode: .edit(model), store: store)
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
    
    
    // MARK: - Sections
    
    private var isToday: Bool {
        date.startOfDay == now.startOfDay
    }
    
    /// The stretch of the day `now` sits in — only meaningful on today's page.
    private func isCurrentSegment(_ segment: CalendarDayViewModel.TimeOfDay) -> Bool {
        isToday && segment.contains(hour: now.hours)
    }
    
    private func isCollapsed(_ segment: CalendarDayViewModel.TimeOfDay) -> Bool {
        collapsedSegments.contains(segment)
    }
    
    @ViewBuilder
    private func sectionHeader(_ section: CalendarDayViewModel.Section) -> some View {
        Button {
            SensoryFeedbackManager.shared.playSelection()
            withAnimation(.snappy) {
                if collapsedSegments.contains(section.timeOfDay) {
                    collapsedSegments.remove(section.timeOfDay)
                } else {
                    collapsedSegments.insert(section.timeOfDay)
                }
            }
        } label: {
            DaySegmentHeaderView(segment: section.timeOfDay,
                                 completedCount: section.completedCount,
                                 totalCount: section.reminders.count,
                                 isCurrent: isCurrentSegment(section.timeOfDay),
                                 isCollapsed: isCollapsed(section.timeOfDay))
        }
        .buttonStyle(.plain)
        .padding(.bottom, 10)
    }
    
    @ViewBuilder
    private func sectionContent(_ section: CalendarDayViewModel.Section) -> some View {
        if section.reminders.isEmpty {
            DaySegmentEmptyRow(segment: section.timeOfDay)
                .padding(.bottom, 10)
        } else {
            ForEach(section.reminders) { model in
                Button {
                    self.presentation = .editReminder(model.reminder)
                } label: {
                    RoutineCardView(model: model.viewConfig, now: now)
                        .id(model)
                        .padding(.bottom, 10)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

extension CalendarDayView: PageContentView {
    
    public struct Model: Hashable {
        let store: Store
        let calendarDay: CalendarDay
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(calendarDay)
        }
        
        public static func ==(lhs: Model, rhs: Model) -> Bool {
            lhs.calendarDay == rhs.calendarDay
        }
    }
    
    public init(model: Model) {
        self.init(store: model.store, calendarDay: model.calendarDay)
    }
    
}
