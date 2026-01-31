//
//  ReminderWeekPlannerView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 24/01/2026.
//

import SwiftUI
import VanorUI
import Model

struct ReminderWeekPlannerView: View {
    
    enum Day: CaseIterable, Identifiable {
        case sunday, monday, tuesday, wednesday, thursday, friday, saturday
        
        var id: Int {
            switch self {
            case .sunday: return 0
            case .monday: return 1
            case .tuesday: return 2
            case .wednesday: return 3
            case .thursday: return 4
            case .friday: return 5
            case .saturday: return 6
            }
        }
    }
    
    enum ReminderType {
        case weekly
        case monthly
    }
    
    @State private var weekInterval: Int = 1
    @State private var selectedDays: Set<Day> = []
    @State private var reminderType: ReminderType = .weekly
    @State private var datesInMonth: Set<Int> = []
    
    @Environment(\.dismiss) var dismiss
    private let dateToSelect: Int
    let action: (Reminder.ScheduleBuilder) -> Void
    
    init(action: @escaping (Reminder.ScheduleBuilder) -> Void) {
        dateToSelect = Date.now.day
        self.action = action
    }
    
    var buttonDisabled: Bool {
        switch reminderType {
        case .weekly:
            selectedDays.isEmpty
        case .monthly:
            datesInMonth.isEmpty
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            
            Text("Reminder Schedule")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Picker(selection: $reminderType) {
                Text("Weekly")
                    .font(.headline)
                    .tag(ReminderType.weekly)
                Text("Monthly")
                    .font(.headline)
                    .tag(ReminderType.monthly)
            } label: {
                Label("Reminder Type", systemSymbol: .arrow2Squarepath)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .pickerStyle(.segmented)
            .labelsVisibility(.visible)
            
            switch reminderType {
            case .weekly:
                VStack(alignment: .center, spacing: 16) {
                HStack(alignment: .center, spacing: 8) {
                    ForEach(Day.allCases, id: \.self) { day in
                        Button {
                            if selectedDays.contains(day) {
                                selectedDays.remove(day)
                            } else {
                                selectedDays.insert(day)
                            }
                        } label: {
                            Text(Calendar.current.shortStandaloneWeekdaySymbols[day.id])
                                .font(.headline)
                        }
                        .buttonStyle(.circleGlass(.regular.tint(selectedDays.contains(day) ? Color.proSky.outlinePrimary : nil)))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .frame(height: 56)
                    }
                }
                
                Menu("\(weekInterval == 1 ? "Every week" : "Every \(weekInterval) weeks")") {
                    Button("every Week") {
                        weekInterval = 1
                    }
                    Button("every 2 Week") {
                        weekInterval = 2
                    }
                    Button("every 3 Week") {
                        weekInterval = 3
                    }
                    Button("every 4 Week") {
                        weekInterval = 4
                    }
                    Button("every 5 Week") {
                        weekInterval = 5
                    }
                }
                .font(.headline)
                .buttonStyle(.glass)
            }
                
            case .monthly:
               DateGridView(datesInMonth: $datesInMonth)
            }
        }
        .animation(.easeInOut, value: datesInMonth)
        .padding(.init(top: 20, leading: 20, bottom: 12, trailing: 16))
        .safeAreaInset(edge: .bottom, content: {
            Button {
                submitSchedule()
                dismiss()
            } label: {
                Text("Confirm")
                    .font(.headline)
                    .padding(.init(top: 12, leading: 14, bottom: 12, trailing: 14))
                    .dynamicTypeSize(..<DynamicTypeSize.large)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .tint(Color.proSky.baseColor)
            .buttonStyle(.glass)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .center)
            .disabled(buttonDisabled)
        })
    }
    
    
    private func submitSchedule() {
        let scheduleBuilder: Reminder.ScheduleBuilder
        switch reminderType {
        case .weekly:
            scheduleBuilder = .init(intervalWeek: nil, weekdays: Set(selectedDays.map(\.id)), dates: nil)
        case .monthly:
            scheduleBuilder = .init(intervalWeek: nil, weekdays: nil, dates: Set(datesInMonth))
        }
        
        action(scheduleBuilder)
    }
    
    
    // MARK: - DateGridView
    
    struct DateGridView: View {
        
        @Binding var datesInMonth: Set<Int>
        
        private var datesInMonthString: AttributedString {
            guard !datesInMonth.isEmpty else {
                return .init("Choose a day in a month.", attributes: .init([.font: UIFont.preferredFont(for: .subheadline, weight: .medium)]))
            }
            let mutatableAttributedString: NSMutableAttributedString = .init()
            for date in datesInMonth.sorted() {
                let string: String
                if mutatableAttributedString.string.isEmpty {
                    string = "\(date)."
                } else {
                    string = ", \(date)."
                }
                
                let dateAttributedString = NSAttributedString(string: string, attributes: [.font: UIFont.preferredFont(for: .subheadline, weight: .semibold)])
                mutatableAttributedString.append(dateAttributedString)
            }
            
            mutatableAttributedString.append(.init(string: " every month", attributes: [.font: UIFont.preferredFont(for: .subheadline, weight: .medium)]))
            
            return AttributedString(mutatableAttributedString)
        }
        
        var body: some View {
            VStack(alignment: .center, spacing: 16) {
                GridLayout(spacing: 0, dimension: .fractional(.init(side: .width, factor: 1 / 7, otherDimension: .absolute(44)))) {
                    ForEach(1..<32) { date in
                        Button {
                            if datesInMonth.contains(date) {
                                self.datesInMonth.remove(date)
                            } else {
                                self.datesInMonth.insert(date)
                            }
                        } label: {
                            Text("\(date)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .aspectRatio(1, contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                .background(alignment: .center) {
                                    if datesInMonth.contains(date) {
                                        Circle()
                                            .fill(Color.backgroundSecondary)
                                    }
                                }
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .layoutPriority(2)
                .clipped()
                
                Text(datesInMonthString)
                    .contentTransition(.opacity)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }.task {
                print("(DEBUG) set Date!")
                self.datesInMonth = [Date.now.day]
            }
            
        }
            
    }
}


#Preview {
    ReminderWeekPlannerView { scheduleBuilder in
        print("(DEBUG) Schedule Builder: \(scheduleBuilder)")
    }
}
