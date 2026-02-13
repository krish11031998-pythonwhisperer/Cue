//
//  TodayTabView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 19/01/2026.
//

import Foundation
import SwiftUI
import Model
import VanorUI
internal import EmojiKit

extension CalendarDay: @retroactive CalendarDateCarouselDataElement, @retroactive Identifiable {
    public var id: Int {
        date.hashValue
    }
}

struct TodayTabView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(Store.self) var store
    @Environment(SubscriptionManager.self) var subscriptionManager
    private var presentCreateReminder: () -> Void
    @State private var viewModel: TodayViewModel = .init()
    @State private var topPadding: CGFloat = .zero
    
    init(presentCreateReminder: @escaping () -> Void) {
        self.presentCreateReminder = presentCreateReminder
    }
    
    var id: Int {
        var hasher = Hasher()
        store.reminders.forEach { hasher.combine($0.hashValue) }
        return hasher.finalize()
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .center) {
                Color(uiColor: .systemBackground)
                if store.reminders.isEmpty {
                    ContentUnavailableView("No Reminders", systemImage: "bell.fill", description: descriptionText)
                        .font(.headline)
                } else {
                    tabView()
                }
            }
            .toolbar {
                if viewModel.today.isToday == false {
                    ToolbarItem(placement: .title) {
                        Button {
                            withAnimation(.easeInOut) {
                                self.viewModel.today = Date.now.startOfDay
                            }
                        } label: {
                            Text("Today")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .buttonStyle(.glass)
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.easeInOut) {
                            self.viewModel.fullPresentation = .calendar
                        }
                    } label: {
                        Image(systemSymbol: .calendar)
                            .font(.headline)
                    }
                }
                
                #if DEBUG
                if subscriptionManager.userIsPro {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            print("(DEBUG) showTimer")
                            viewModel.presentation = .timer
                        } label: {
                            Image(systemSymbol: .timer)
                                .font(.headline)
                        }
                        .tint(Color.proSky.baseColor)
                    }
                }
                #endif
            }
        }
        .onChange(of: viewModel.today, { _, _ in
            if store.user?.hapticsEnabled == true {
                SensoryFeedbackManager.shared.playSelection()                
            }
        })
        .task(id: store.reminders) {
            viewModel.setupCalendarForOneMonth(reminders: store.reminders)
        }
        .task {
            for await _ in store.hasLoggedReminder {
                viewModel.setupCalendarForOneMonth(reminders: store.reminders)
            }
        }
        .sheet(item: $viewModel.presentation, content: { presentation in
            switch presentation {
            case .timer:
                TimerSheet(reminderModels: viewModel.reminderWithTimer) { selectedReminder, timeDuration in
                    withAnimation {
                        self.viewModel.presentation = nil
                    } completion: {
                        self.viewModel.fullPresentation = .focusTimer(selectedReminder, timeDuration)
                    }
                }
                .fittedPresentationDetent()
            }
        })
        .fullScreenCover(item: $viewModel.fullPresentation,
                         content: { sheet in
            switch sheet {
            case .calendar:
                CalendarView {
                    self.dismiss()
                    self.presentCreateReminder()
                }
            case .focusTimer(let reminderModel, let duration):
                TimerView(reminder: reminderModel, duration: duration)
            }
        })
      
    }
    
    private func tabView() -> some View {
        TabView(selection: $viewModel.today) {
            ForEach(viewModel.calendarDay, id: \.date) { calendarDay in
                CalendarDayView(store: store, calendarDay: calendarDay, presentCreateReminder: presentCreateReminder)
                    .tag(calendarDay.date)
                    .environment(\.timeCompactViewTopPadding, topPadding)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .indexViewStyle(.page(backgroundDisplayMode: .never))
        .safeAreaBar(edge: .top, alignment: .center, spacing: 0, content: {
            CalendarDateCarousel(dateElements: viewModel.calendarDay, selectedDate: viewModel.todayInCalendar)
                .background { Color.clear }
                .scrollIndicators(.hidden)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGSize.self, of: { $0.size }) { newValue in
                    self.topPadding = newValue.height
                }
        })
    }
    
    
    // MARK: - DescriptionText
    
    private var descriptionText: Text {
        Text("Add Reminders to start organizing your day.")
            .font(.caption)
            .foregroundColor(.foregroundSecondary)
    }
}
