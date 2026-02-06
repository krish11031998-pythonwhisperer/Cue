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
    @State private var viewModel: CalendarDayViewModel
    @Environment(\.timeCompactViewTopPadding) var topPadding
    
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
                DateView(todayModel: .init(date: date, showArc: true))
                    .padding(.bottom, 32)
                if !calendarDay.reminders.isEmpty {
                    ForEach(viewModel.sections(calendarDay: calendarDay)) { section in
                        Section {
                            ForEach(section.reminders) { model in
                                Button {
                                    self.presentation = .editReminder(model.reminder)
                                } label: {
                                    ReminderView(model: model.viewConfig)
                                        .id(model)
                                        .padding(.bottom, 8)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            SectionHeader(section: section.timeOfDay)
                                .padding(.bottom, 8)
                        }
                        .padding(.bottom, 12)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .ignoresSafeArea(edges: .bottom)
        .scrollEdgeEffectStyle(.soft, for: .bottom)
        .sheet(item: $presentation, content: { presentation in
            switch presentation {
            case .editReminder(let model):
                CreateReminderView(mode: .edit(model), store: store)
                    .presentationDetents([.fraction(1)])
            }
        })
        .background(alignment: .center) {
            if calendarDay.reminders.isEmpty {
                ContentUnavailableView {
                    Image(systemSymbol: .squareSlash)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120, alignment: .center)
                } description: {
                    Text("There is nothing in the Cue yet.")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .fontWeight(.semibold)
                        .padding(.top, 12)
                } actions: {
                    Button {
                        print("(DEBUG) add reminders")
                    } label: {
                        Text("Add an reminder")
                            .font(.headline)
                            .padding(.init(top: 8, leading: 12, bottom: 8, trailing: 12))
                            .font(.headline)
                    }
                    .buttonStyle(.glass)
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
        
        var body: some View {
            HStack(alignment: .bottom, spacing: 4) {
                Image(systemSymbol: section.symbol)
                Text(section.title)
            }
            .font(.footnote)
            .fontWeight(.medium)
            .padding(.init(top: 6, leading: 12, bottom: 6, trailing: 12))
            .background(section.color.surfacePrimary, in: .capsule)
        }
    }
}
