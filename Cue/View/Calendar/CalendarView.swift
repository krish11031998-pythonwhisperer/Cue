//
//  CalendarView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 03/02/2026.
//

import SwiftUI
import VanorUI
import Model

struct CalendarView: View {
    
    @Environment(Store.self) var store
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var size: CGSize = .zero
    @State private var viewModel: CalendarViewModel = .init()
    @State private var selectedCalendarDay: CalendarDay? = nil
    
    var chipBackgroundColor: Color {
        switch colorScheme {
        case .light:
            Color.backgroundSecondary
        case .dark:
            Color.invertedBackgroundSecondary
        @unknown default:
            Color.backgroundSecondary
        }
    }
    
    var emptyChipBackgroundColor: Color {
        switch colorScheme {
        case .light:
            Color.backgroundSecondary.opacity(0.05)
        case .dark:
            Color.invertedBackgroundSecondary.opacity(0.05)
        @unknown default:
            Color.backgroundSecondary.opacity(0.05)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                LazyVGrid(columns: [.init(.adaptive(minimum: max(44, size.width / 7).rounded(.down)),
                                          spacing: 0,
                                          alignment: .center)],
                          alignment: .center,
                          spacing: 8) {
                    ForEach(viewModel.calendarData) { section in
                        sectionBuilder(section: section)
                    }
                }
                .onGeometryChange(for: CGSize.self, of: { $0.size }) { newValue in
                    self.size = newValue
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("", systemSymbol: .xmark) {
                        dismiss()
                    }
                }
            }
        }
        .task {
            viewModel.fetchCalendarSection()
        }
        .sheet(item: $selectedCalendarDay) { selectedCalendarDay in
            CalendaryDetailSheetView(calendarDay: selectedCalendarDay)
                .fittedPresentationDetent()
        }
    }
    
    
    // MARK: - SectionBuilder
    
    @ViewBuilder
    func sectionBuilder(section: CalendarViewModel.Section) -> some View {
        Section {
            if section.firstDayInMonth < 7 {
                ForEach(0..<section.firstDayInMonth, id: \.self) { id in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(emptyChipBackgroundColor)
                        .padding(.horizontal, 2)
                        .id("\(section)-\(id)")
                }
            }
            ForEach(section.days) { day in
                Button {
                    self.selectedCalendarDay = day
                } label: {
                    CalendarChips(config: .init(date: day.date, baseColor: chipBackgroundColor)) {
                        Group {
                            if let bubble = viewModel.buildBubbleConfig(for: day) {
                                ReminderBubbleView(element: bubble, withGlass: false)
                            } else {
                                CalendarChipUnloggedContent(count: day.reminders.count)
                            }
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 2)
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text(Calendar.current.monthSymbols[section.month - 1])
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, 12)
    }
}
