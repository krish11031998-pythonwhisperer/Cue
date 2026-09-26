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
import Combine

extension CalendarDay: @retroactive CalendarDateCarouselDataElement, @retroactive Identifiable {
    public var id: Int {
        date.hashValue
    }
}

struct TodayTabView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(Store.self) var store
    @Environment(SubscriptionManager.self) var subscriptionManager
    let startDate: Date?
    @State private var viewModel: TodayViewModel = .init()
    @State private var topPadding: CGFloat = .zero

    init(startDate: Date? = nil) {
        self.startDate = startDate
    }
    
    var id: Int {
        var hasher = Hasher()
        store.reminderModels.forEach { hasher.combine($0.hashValue) }
        return hasher.finalize()
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            Color.cueItBackground
                .ignoresSafeArea(.all)
            if store.reminderModels.isEmpty {
                ContentUnavailableView("No Reminders", systemImage: "bell.fill", description: descriptionText)
                    .font(.headline)
            } else {
                tabView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.easeInOut) {
                        self.viewModel.fullPresentation = .settings
                    }
                } label: {
                    Image(systemSymbol: .gearshape)
                        .font(.headline)
                }
            }
            
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemSymbol: .calendar)
                        .font(.headline)
                }
            }
        }
        .task(id: startDate) { @MainActor in
            if let startDate {
                self.viewModel.today = startDate.startOfDay
            }
        }
        .preference(key: IsTodayPreferenceKey.self, value: viewModel.todayInCalendar?.date.startOfDay == viewModel.today.startOfDay)
        .onChange(of: viewModel.today, { _, _ in
            if store.userModel?.hapticsEnabled == true {
                SensoryFeedbackManager.shared.playSelection()                
            }
        })
        .task(id: store.reminderModels) {
            viewModel.setupCalendarForOneMonth(reminders: store.reminderModels)
        }
        .task {
            for await _ in store.hasLoggedReminder {
                viewModel.setupCalendarForOneMonth(reminders: store.reminderModels)
            }
        }
        .fullScreenCover(item: $viewModel.fullPresentation, content: fullScreenPresentationContent(_:))
    }
    
    
    // MARK: - Presentation
    
    @ViewBuilder
    private func fullScreenPresentationContent(_ presentation: TodayViewModel.FullScreenPresentation) -> some View {
        switch presentation {
        case .focusTimer(let reminderModel, let loggedReminderTasks, let duration):
            TimerView(reminder: reminderModel, loggedTasks: loggedReminderTasks, duration: duration)
        case .settings:
            SettingView()
        }
    }
    
    @ViewBuilder
    private func tabView() -> some View {
        let current: Binding<CalendarDayView.Model?> = .init {
            guard let todayCalendar = viewModel.todayInCalendar else { return nil }
            return .init(store: store, calendarDay: todayCalendar)
        } set: { model in
            guard let calendarDate = model?.calendarDay.date else { return }
            viewModel.today = calendarDate
        }
    
        PageView<CalendarDayView>(models: viewModel.calendarDay.map { .init(store: store, calendarDay: $0) },
                                  current: current)
        .environment(\.screenPadding, .init(topPadding: topPadding, bottomPadding: 83))
        .ignoresSafeArea(edges: .vertical)
        .safeAreaBar(edge: .top, alignment: .center, spacing: 0, content: {
            CalendarDateCarousel(dateElements: viewModel.calendarDay, selectedDate: viewModel.todayInCalendar)
                .scrollIndicators(.hidden)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { newValue in
                    self.topPadding = newValue.maxY
                }
                .disabled(true)
        })
        .safeAreaInset(edge: .bottom, content: {
            if viewModel.todayInCalendar?.date.startOfDay != viewModel.today.startOfDay {
                Button {
                    withAnimation(.easeInOut) {
                        self.viewModel.today = Date.now.startOfDay
                    }
                } label: {
                    Text("today")
                        .font(.bitcountRegular(style: .body))
                        .padding(.init(top: 8, leading: 10, bottom: 8, trailing: 10))
                }
                .buttonStyle(.glass)
                .padding(.bottom, 12)
            }
        })
        .environment(\.theme, .init(color: Color.cueItBackground))
    }

    
    // MARK: - DescriptionText
    
    private var descriptionText: Text {
        Text("Add Reminders to start organizing your day.")
            .font(.caption)
            .foregroundColor(.foregroundSecondary)
    }
}
