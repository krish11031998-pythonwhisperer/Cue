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
    enum Presentation: Int, Identifiable {
        case reminderDetail = 0
        
        var id: Int { rawValue }
    }
    
    enum FullScreenSheet: Int, Identifiable {
        case calendar = 0
        
        var id: Int { rawValue }
    }
    
    @Environment(\.dismiss) var dismiss
    @Environment(Store.self) var store
    private var presentCreateReminder: () -> Void
    @State private var presentation: Presentation? = nil
    @State private var fullScreenSheet: FullScreenSheet? = nil
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
                            self.fullScreenSheet = .calendar
                        }
                    } label: {
                        Image(systemSymbol: .calendar)
                            .font(.body)
                    }

                }
            }
        }
        .task(id: store.reminders) {
            viewModel.setupCalendarForOneMonth(reminders: store.reminders)
        }
        .task {
            for await _ in store.hasLoggedReminder {
                viewModel.setupCalendarForOneMonth(reminders: store.reminders)
            }
        }
        .fullScreenCover(item: $fullScreenSheet,
                         content: { sheet in
            switch sheet {
            case .calendar:
                CalendarView {
                    self.dismiss()
                    self.presentCreateReminder()
                }
            }
        })
      
    }
    
    private func tabView() -> some View {
        TabView(selection: $viewModel.today) {
            ForEach(viewModel.calendarDay, id: \.date) { calendarDay in
                CalendarDayView(store: store, calendarDay: calendarDay)
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
