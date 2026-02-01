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
        case addReminder = 0
        
        var id: Int { rawValue }
    }
    
    let store: Store
    @State private var presentation: Presentation? = nil
    @State private var viewModel: TodayViewModel = .init()
    @State private var topPadding: CGFloat = .zero
    
    init(store: Store) {
        self.store = store
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .center) {
                Color(uiColor: .systemBackground)
                if store.reminders.isEmpty {
                    ContentUnavailableView("No Reminders", systemImage: "bell.fill", description: descriptionText)
                        .font(.headline)
                } else if let today = viewModel.today {
                    TabView(selection: $viewModel.today) {
                        ForEach(viewModel.calendarDay, id: \.date) { calendarDay in
                            CalendarDayView(store: store, calendarDay: calendarDay)
                                .tag(calendarDay)
                                .environment(\.timeCompactViewTopPadding, topPadding)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .indexViewStyle(.page(backgroundDisplayMode: .never))
                    .safeAreaBar(edge: .top, alignment: .center, spacing: 0, content: {
                        CalendarDateCarousel(dateElements: viewModel.calendarDay, selectedDate: today)
                            .background { Color.clear }
                            .scrollIndicators(.hidden)
                            .fixedSize(horizontal: false, vertical: true)
                            .onGeometryChange(for: CGSize.self, of: { $0.size }) { newValue in
                                self.topPadding = newValue.height
                            }
                    })
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.presentation = .addReminder
                    } label: {
                        Image(systemSymbol: .plus)
                            .font(.body)
                    }
                }
            }
        }
        .task(id: store.reminders) {
            viewModel.setupCalendarForOneMonth(reminders: store.reminders)
        }
        .sheet(item: $presentation) { presentation in
            switch presentation {
            case .addReminder:
                CreateReminderView(store: store)
                    .presentationDetents([.fraction(1)])
            }
        }
    }
    
    
    // MARK: - DescriptionText
    
    private var descriptionText: Text {
        Text("Add Reminders to start organizing your day.")
            .font(.caption)
            .foregroundColor(.foregroundSecondary)
    }
}
