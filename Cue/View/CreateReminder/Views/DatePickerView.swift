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
    #warning("Make this a seperate enum!")
    @Binding var notification: ReminderNotification
    let viewType: ViewType
    
    static func time(_ title: String, date: Binding<Date>, notification: Binding<ReminderNotification>) -> DatePickerView {
        .init(date: date, notification: notification, viewType: .time(title, notification.wrappedValue == .alarm ? .alarmWavesLeftAndRightFill : .bellAndWavesLeftAndRightFill))
    }
    
    static func date(_ title: String, date: Binding<Date>) -> DatePickerView {
        .init(date: date, notification: .constant(.alarm), viewType: .date(title, .calendar))
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            VStack(alignment: .center, spacing: 6) {
                Label(viewType.title, systemSymbol: viewType.symbol)
                    .font(.subheadline)
                    .fontWeight(.semibold)
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
            }
            .foregroundStyle(.secondary)
            .padding(.top, 32)
            
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
