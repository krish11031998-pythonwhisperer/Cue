//
//  TodayCalendarView.swift
//  Kyu
//
//  Created by Krishna Venkatramani on 09/09/2026.
//

import Foundation
import SwiftUI
import VanorUI
import Model

struct TodayCalendarView: View {
    
    @Namespace var namespace
    @Environment(\.colorScheme) var colorScheme
    @State private var viewModel: TodayCalendarViewModel = .init()
    @State private var size: CGSize = .zero
    
    typealias Path = TodayCalendarViewModel.Path
    
    var body: some View {
        NavigationStack(path: $viewModel.path) {
            Group {
                if let currentMonth = viewModel.currentMonth {
                    VStack(alignment: .center, spacing: 16) {
                        
                        LazyVGrid(columns: [.init(.adaptive(minimum: max(44, size.width / 7).rounded(.down)),
                                                  spacing: 0,
                                                  alignment: .center)],
                                  alignment: .center,
                                  spacing: 4) {
                            sectionBuilder(section: currentMonth)
                        }
                                  .onGeometryChange(for: CGSize.self, of: { $0.size }) { newValue in
                                      self.size = newValue
                                  }
                                  .padding(.horizontal, 16)
                                  .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                } else {
                    ContentUnavailableView("Loading..", systemSymbol: .calendar, description: nil)
                        .task {
                            viewModel.fetchCalendarSection()
                        }
                }
            }
            .navigationDestination(for: Path.self) { path in
                switch path {
                case .day:
                    TodayTabView {
                        
                    }
                    .navigationTransition(.zoom(sourceID: path.id, in: namespace))
                    .navigationBarBackButtonHidden()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.easeInOut) {
                            self.viewModel.fullScreenPresentation = .settings
                        }
                    } label: {
                        Image(systemSymbol: .gearshape)
                            .font(.headline)
                    }
                }
            }
        }
        .fullScreenCover(item: $viewModel.fullScreenPresentation) { fullScreenPresentation in
            switch fullScreenPresentation {
            case .settings:
                SettingView()
            }
        }
    }
    
    // MARK: - SectionBuilder
    
    @ViewBuilder
    func sectionBuilder(section: TodayCalendarViewModel.Section) -> some View {
        Section {
            if section.firstDayInMonth < 7 {
                ForEach(0..<section.firstDayInMonth - 1, id: \.self) { id in
                    EmptyView()
                        .id("\(section)-\(id)")
                }
            }
            ForEach(section.days) { day in
                Button {
                    self.viewModel.path.append(Path.day(day.date))
                } label: {
                    CalendarChipView(day: day)
                }
                .buttonStyle(.plain)
                .matchedTransitionSource(id: TodayCalendarViewModel.Path.day(day.date).id, in: namespace)
            }
        } header: {
            VStack(alignment: .leading, spacing: 8) {
                Text(Calendar.current.monthSymbols[section.month - 1])
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                WeekdayView()
            }
        }
        .padding(.bottom, 12)
    }
    
    
    // MARK: - Child Views
    
    struct CalendarChipView: View {
        @Environment(\.colorScheme) var colorScheme
        
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
        
        let day: CalendarDay
        var body: some View {
            CalendarChips(config: .init(date: day.date, baseColor: chipBackgroundColor)) {
                Group {
                    if let bubble = buildBubbleConfig(for: day) {
                        ReminderBubbleView(element: bubble, withGlass: false)
                    } else {
                        CalendarChipUnloggedContent(count: day.reminders.count)
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 2)
        }
        
        func buildBubbleConfig(for day: CalendarDay) -> ReminderBubbleView.ElementType? {
            guard !day.loggedReminders.isEmpty else { return nil }
            let firstThreeLoggedReminders = day.loggedReminders.prefix(3)
            
            func getIcon(_ cueIcon: CueIcon) -> Icon {
                if let symbol = cueIcon.symbol {
                    return .symbol(.init(rawValue: symbol))
                } else if let emoji = cueIcon.emoji {
                    return .emoji(.init(emoji))
                } else {
                    fatalError("No Icon!")
                }
            }
            
            
            switch firstThreeLoggedReminders.count {
            case 2, 3:
                return .group(firstThreeLoggedReminders.map({ .init(icon: getIcon($0.reminder.icon), color: Color.proSky.baseColor)}))
            case 1:
                return .single(.init(icon: getIcon(firstThreeLoggedReminders.first!.reminder.icon), color: Color.proSky.baseColor))
            default:
                fatalError("Shouldn't end up here!")
                
            }
        }
        
    }
    
    struct EmptyDayView: View {
        @Environment(\.colorScheme) var colorScheme
        
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
            RoundedRectangle(cornerRadius: 16)
                .fill(emptyChipBackgroundColor)
                .padding(.horizontal, 2)
        }
    }
    
    struct WeekdayView: View {
        var body: some View {
            HStack(alignment: .center, spacing: 0) {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { sym in
                    Text(sym)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
    
}

@Observable
@MainActor
class TodayCalendarViewModel {
    
    struct Section: Identifiable {
        let month: Int
        let days: [CalendarDay]
        
        var id: Int {
            month
        }
        
        var firstDayInMonth: Int {
            guard let firstDay = days.first else {
                fatalError("Must have a first Day!")
            }
            
            return firstDay.date.weekDayValue
        }
    }
    
    enum Path: Identifiable, Hashable {
        case day(Date)
        
        var id: String {
            switch self {
            case .day(let date):
                return "today_\(date.day)_\(date.month)"
            }
        }
    }
    
    enum FullScreenPresentation: Identifiable {
        case settings
        
        var id: String {
            switch self {
            case .settings:
                return "Settings"
            }
        }
    }
    
    @ObservationIgnored
    private var calendarDayTask: Task<Void, Never>?
    var path: [Path] = [.day(.now)]
    var currentMonth: Section? = nil
    var fullScreenPresentation: FullScreenPresentation? = nil
    
    func fetchCalendarSection() {
        calendarDayTask?.cancel()
        calendarDayTask = Task {
            let currentMonth = Calendar.current.dateComponents([.month], from: .now).month!
            //            let months = Array(1...monthCount)
            
            //            let sections: [Section] = await withTaskGroup(of: Section.self) { group in
            //                for i in months {
            //                    group.addTask {
            //                        let calendarDays = await CalendarManager.shared.setupCalendayDaysInCurrentYear(month: i)
            //                        return Section(month: i, days: calendarDays)
            //                    }
            //                }
            //
            //                var sections: [Section] = []
            //                for await section in group {
            //                    sections.append(section)
            //                }
            //
            //                return sections.sorted(by: { $0.month < $1.month })
            //            }
            
            let calendarDays = await CalendarManager.shared.setupCalendayDaysInCurrentYear(month: currentMonth)
            let section = Section(month: currentMonth, days: calendarDays)
            
            await MainActor.run { [weak self] in
                //                self?.calendarData = sections
                self?.currentMonth = section
            }
        }
    }
}

#Preview {
    TodayCalendarView()
}
