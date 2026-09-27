//
//  RoutineCalendarView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 27/09/2026.
//

import SwiftUI
import VanorUI
import Model

// MARK: - Routine Calendar

public struct RoutineCalendarView: View {
    
    public struct Day: Hashable, Identifiable {
        let isLogged: Bool
        let date: Date
        let wasScheduled: Bool
        
        nonisolated
        public init(isLogged: Bool, date: Date, wasScheduled: Bool) {
            self.isLogged = isLogged
            self.date = date
            self.wasScheduled = wasScheduled
        }
        
        public var id: Int {
            hashValue
        }
    }
    
    public struct Config: Hashable {
        let month: Int
        let schedule: ReminderSchedule?
        let calendarDay: [Day]
        let color: Color
        
        public init(month: Int, schedule: ReminderSchedule?, calendarDay: [Day], color: Color) {
            self.month = month
            self.schedule = schedule
            self.calendarDay = calendarDay
            self.color = color
        }
    }
    
    let config: Config
    
    private var theme: LCHColor {
        .init(color: config.color)
    }
    
    public init(model: Config) {
        self.config = model
    }
    
    private var firstWeekdayOfMonth: Int {
        let firstDayOfMonth = Calendar.current.date(bySetting: .month, value: config.month, of: Date.now)?.startOfMonth ?? Date.now.startOfMonth
        let firstWeekdayOfMonth = firstDayOfMonth.weekDayValue
        return firstWeekdayOfMonth
    }
    
    private var currentMonth: String {
        let currentMonth = Date.now.month
        return Calendar.current.monthSymbols[currentMonth - 1]
    }
    
    public var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                WeekdayHeader()
                
                GridLayout(spacing: 0, dimension: .fractional(.init(side: .width, factor: 1/7, otherDimension: .aspectRatio(1)))) {
                    if firstWeekdayOfMonth < 7 {
                        ForEach(0..<(firstWeekdayOfMonth - 1), id: \.self) { id in
                            Circle()
                                .fill(theme.backgroundPrimary)
                                .aspectRatio(1, contentMode: .fill)
                                .padding(.all, 4)
                                .id("\(Date.now.month)-\(id)")
                        }
                    }
                    
                    ForEach(config.calendarDay) { calendarDay in
                        DayChip(day: calendarDay, color: config.color)
                    }
                }
                
                Legend()
            }
            .padding(.top, 4)
            .environment(\.theme, config.color.themedVariants)
        } label: {
            Text(currentMonth.uppercased())
                .font(.bitcountMedium(style: .footnote))
                .foregroundStyle(.secondary)
        }
        .groupBoxStyle(RoutineDetailGroupBox(style: .default))
    }
    
    
    // MARK: Child Views
    
    private struct DayChip: View {
        let day: Day
        let color: Color
        
        var theme: LCHColor {
            .init(color: color)
        }
        
        private var foregroundColor: Color {
            if day.wasScheduled {
                if day.isLogged {
                    return Color.white
                } else {
                    return theme.foregroundSecondary
                }
            } else {
                return theme.foregroundPrimary
            }
        }
        
        var body: some View {
            Text("\(day.date.day)")
                .font(.headline)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .foregroundStyle(foregroundColor)
                .background(alignment: .center) {
                    background
                }
                .padding(.all, 4)
        }
        
        @ViewBuilder
        private var background: some View {
            if day.wasScheduled {
                if day.isLogged {
                    Circle()
                        .fill(theme.surfacePrimary)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .stroke(theme.outlinePrimary, style: .init(lineWidth: 1))
                }
            } else {
                Color.clear
            }
        }
    }
    
    private struct Legend: View {
        
        @Environment(\.theme) var theme
        
        var body: some View {
            HStack(alignment: .center, spacing: 8) {
                
                Label {
                    Text("done")
                } icon: {
                    Image(systemSymbol: .circleFill)
                        .foregroundStyle(theme.surfacePrimary)
                }
                .font(.caption)
                .labelStyle(SmallLabelStyle(withFont: false))
                
                Label {
                    Text("planned")
                } icon: {
                    Image(systemSymbol: .circle)
                        .foregroundStyle(theme.outlinePrimary)
                }
                .font(.caption)
                .labelStyle(SmallLabelStyle(withFont: false))
            
            }
        }
    }
    
    private struct WeekdayHeader: View {
        var body: some View {
            HStack(alignment: .center, spacing: 0) {
                ForEach(Calendar.current.veryShortStandaloneWeekdaySymbols.enumerated(), id: \.offset) { weekday in
                    Text(weekday.element.uppercased())
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
}
