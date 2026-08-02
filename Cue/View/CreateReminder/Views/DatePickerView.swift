//
//  DatePickerView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 08/02/2026.
//

import SwiftUI
import VanorUI
import Model

struct DatePickerView: View {
    enum ViewType {
        case time(String, SFSymbol)
        case date(String, SFSymbol)
        
        var title: String {
            switch self {
            case .time(let string, _):
                return string
            case .date(let string, _):
                return string
            }
        }
        
        var symbol: SFSymbol {
            switch self {
            case .time(_, let sFSymbol):
                return sFSymbol
            case .date(_, let sFSymbol):
                return sFSymbol
            }
        }
    }
    
    @Binding var date: Date
    #if !NEW_CREATE_REMINDER
    #warning("Make this a seperate enum!")
    @Binding var notification: ReminderNotification
    #endif
    let viewType: ViewType
    
    #if NEW_CREATE_REMINDER
    init(date: Binding<Date>, viewType: ViewType) {
        self._date = date
        self.viewType = viewType
    }
    #else
    init(date: Binding<Date>, notification: Binding<ReminderNotification>, viewType: ViewType) {
        self.date = date
        self.notification = notification
        self.viewType = viewType
    }
    #endif
    
    
    #if NEW_CREATE_REMINDER
    static func time(_ title: String, date: Binding<Date>) -> DatePickerView {
        .init(date: date, viewType: .time(title, .alarmWavesLeftAndRightFill))
    }
    
    static func date(_ title: String, date: Binding<Date>) -> DatePickerView {
        .init(date: date, viewType: .date(title, .calendar))
    }
    #else
    static func time(_ title: String, date: Binding<Date>, notification: Binding<ReminderNotification>) -> DatePickerView {
        .init(date: date, notification: notification, viewType: .time(title, notification.wrappedValue == .alarm ? .alarmWavesLeftAndRightFill : .bellAndWavesLeftAndRightFill))
    }
    
    static func date(_ title: String, date: Binding<Date>) -> DatePickerView {
        .init(date: date, notification: .constant(.alarm), viewType: .date(title, .calendar))
    }
    #endif
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            VStack(alignment: .center, spacing: 6) {
                Label(viewType.title, systemSymbol: viewType.symbol)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                #if NEW_CREATE_REMINDER
                Text("You will receive an notification to remind you")
                    .font(.caption2)
                #else
                Group {
                    switch notification {
                    case .alarm:
                        Text("You will receive an alarm to remind you")
                    case .notification:
                        Text("You will receive an notification to remind you")
                    default:
                        fatalError("Shouldn't happen")
                    }
                }
                .font(.caption2)
                #endif
            }
            .foregroundStyle(.secondary)
            .padding(.top, 32)
            
            #if !NEW_CREATE_REMINDER
            if case .time = viewType {
                Picker("Notification type", selection: $notification) {
                    Text("Notification")
                        .tag(ReminderNotification.notification)
                    Text("Alarm")
                        .tag(ReminderNotification.alarm)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            #endif
            
            Group {
                switch viewType {
                case .time:
                    DatePicker(selection: $date, displayedComponents: [.hourAndMinute]) {
                        Text("DatePicker")
                    }
                    .datePickerStyle(.wheel)
                case .date:
                    DatePicker(selection: $date, displayedComponents: [.date]) {
                        Text("DatePicker")
                    }
                    .datePickerStyle(.graphical)
                }
            }
            .labelsHidden()
        }
        .padding(.horizontal, 20)
    }
    
}
