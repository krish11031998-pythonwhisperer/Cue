//
//  RoutineHeaderView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 27/09/2026.
//

import SwiftUI
import VanorUI
import Model


// MARK: - RoutineHeaderView

public struct RoutineHeaderView: ConfigurableView {
    
    public struct Config: Hashable, Sendable {
        let name: String
        let icon: Icon
        let color: Color
        let time: Date
        let nudge: ReminderNotification
        let scheduleString: String
        let tags: [TagModel]
        
        var theme: LCHColor {
            .init(color: color)
        }
    }
    
    let config: Config
    
    public init(model: Config) {
        self.config = model
    }
    
    fileprivate var chips: [RoutineChips.Chip] {
        var chips: [RoutineChips.Chip] = [.nudge(config.time, config.nudge), .schedule(config.scheduleString)]
        config.tags.forEach { tag in
            chips.append(.tag(tag.name, tag.color))
        }
        return chips
    }
    
    public var body: some View {
        VStack(alignment: .center, spacing: 0) {
            ReminderIconView(icon: config.icon, foregroundColor: .clear, backgroundColor: config.theme.surfaceSecondary, font: .largeTitle)
                .dynamicTypeSize(..<DynamicTypeSize.large)
                .frame(width: 96, height: 96, alignment: .center)
                .background(alignment: .center) {
                    Circle()
                        .fill(config.theme.surfaceSecondary)
                        .stroke(config.theme.outlinePrimary, style: .init(lineWidth: 1))
                }
            
            Text(config.name)
                .font(.bitcountMedium(style: .title1))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 12)
            
            RoutineChips(color: config.color,
                         chips: chips)
            .padding(.top, 16)
        }
    }
    
    // MARK: Routine Chips
    
    fileprivate struct RoutineChips: View {
        
        enum Chip: Identifiable {
            case nudge(Date, ReminderNotification)
            case tag(String, Color)
            case schedule(String)
            
            var id: String {
                switch self {
                case .nudge(let date, let reminderNotification):
                    return "nudge-\(date.dateStringFormatter())-\(reminderNotification.rawValue)"
                case .schedule(let string):
                    return "schedule-\(string)"
                case .tag(let tag, _):
                    return "tag-\(tag)"
                }
            }
            
            var symbol: SFSymbol {
                switch self {
                case .nudge(_, let notification):
                    switch notification {
                    case .alarm:
                        return .alarmWavesLeftAndRightFill
                    case .notification:
                        return .bellAndWavesLeftAndRightFill
                    @unknown default:
                        return .bell
                    }
                case .schedule(let string):
                    return .arrowTrianglehead2Clockwise
                case .tag:
                    return .circleFill
                }
            }
            
            var stringContent: String {
                switch self {
                case .nudge(let date, _):
                    return date.timeBuilder()
                case .schedule(let string):
                    return string
                case .tag(let tagName, _):
                    return tagName
                }
            }
        }
        
        let color: Color
        let chips: [Chip]
        
        var body: some View {
            CentralizedOverFlowingHorizontalLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(chips) { chip in
                    if case .tag(_, let color) = chip {
                        Label {
                            Text(chip.stringContent)
                        } icon: {
                            Image(systemSymbol: chip.symbol)
                        }
                        .font(.caption)
                        .labelStyle(SmallChipStyle(color: color, overgrowVertically: true))
                    } else {
                        Label {
                            Text(chip.stringContent)
                        } icon: {
                            Image(systemSymbol: chip.symbol)
                        }
                        .font(.caption)
                        .labelStyle(SmallChipStyle(color: color, overgrowVertically: true))
                    }
                }
            }
        }
        
    }
    
    public static var viewName: String { "RoutineHeaderView" }
}


struct RoutineHeaderTestView: View {
    
    let model: ReminderModel
    
    init(model: ReminderModel = .exampleFour()) {
        self.model = model
    }
    
    var icon: Icon {
        if let icon = Icon(model.icon) {
            return icon
        } else {
            return .unavailableIcon
        }
    }
    
    var scheduleString: String {
        if let schedule = model.schedule {
            return schedule.timeScheduleString
        } else {
            return ""
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            RoutineHeaderView(model: .init(name: model.title,
                                           icon: icon,
                                           color: model.color,
                                           time: model.date,
                                           nudge: .alarm,
                                           scheduleString: scheduleString,
                                           tags: []))
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview("HeaderView") {
    RoutineHeaderTestView()
}
