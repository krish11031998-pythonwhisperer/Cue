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
    let viewType: ViewType
    
    init(date: Binding<Date>, viewType: ViewType) {
        self._date = date
        self.viewType = viewType
    }
    
    static func time(_ title: String, date: Binding<Date>) -> DatePickerView {
        .init(date: date, viewType: .time(title, .alarmWavesLeftAndRightFill))
    }
    
    static func date(_ title: String, date: Binding<Date>) -> DatePickerView {
        .init(date: date, viewType: .date(title, .calendar))
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            VStack(alignment: .center, spacing: 6) {
                Label(viewType.title, systemSymbol: viewType.symbol)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("You will receive an notification to remind you")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            .padding(.top, 32)
            
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
