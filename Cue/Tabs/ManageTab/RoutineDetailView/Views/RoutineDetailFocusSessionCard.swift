//
//  RoutineDetailFocusSessionCard.swift
//  Cue
//
//  Created by Krishna Venkatramani on 27/09/2026.
//

import SwiftUI
import VanorUI
import FamilyControls
import Model

struct RoutineDetailFocusSessionCard: View {
    
    @Environment(\.theme) var theme
    
    struct Config: Hashable {
        let timeInterval: TimeInterval
        let breakDuration: TimeInterval
        let appBlockSelection: FamilyActivitySelection
        let focusSessionType: FocusSessionType
        let alarm: FocusSessionAlarmOption
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(timeInterval)
            hasher.combine(breakDuration)
            hasher.combine(appBlockSelection.applications)
            hasher.combine(appBlockSelection.categories)
            hasher.combine(appBlockSelection.webDomains)
            hasher.combine(focusSessionType)
            hasher.combine(alarm)
        }
    }
    
    let config: Config
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 0) {
                SessionTypeChipView(sessionType: config.focusSessionType)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 16)
                
                switch config.focusSessionType {
                case .classic:
                    Text(config.timeInterval.mediumTimerDurationString)
                        .font(.bitcountRegular(style: .title2))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                case .pomodoro(let currentIndex, let total):
                    PomodoroSessionInfoView(timeInterval: config.timeInterval, breakDuration: config.breakDuration, rounds: total)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    ConfigurationRow(config: .appBlock(config.appBlockSelection))
//                    Divider()
                    DashLine()
                        .padding(.horizontal, 12)
                        .foregroundStyle(theme.backgroundTertiary)
                        .background(theme.backgroundSecondary, in: .rect)
                    ConfigurationRow(config: .alarm(config.alarm))
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.top, 16)
            }
        } label: {
            Text("Focus Session".uppercased())
                .font(.bitcountMedium(style: .footnote))
                .foregroundStyle(.secondary)
        }
        .groupBoxStyle(RoutineDetailGroupBox(style: .themed(theme)))
    }
    
    
    // MARK: - Child Views
    
    private struct PomodoroSessionInfoView: View {
        
        @Environment(\.theme) var theme
        
        let timeInterval: TimeInterval
        let breakDuration: TimeInterval
        let rounds: Int
        
        var attributedTitle: AttributedString {
            var rounds = AttributedString("\(rounds) rounds")
            rounds.font = .bitcountRegular(style: .title2)
            rounds.foregroundColor = theme.foregroundPrimary

            var session = AttributedString("\(String.separator) \(timeInterval.longTimerDurationString) each, \(breakDuration.longTimerDurationString) break")
            session.font = .footnote.weight(.medium)
            session.foregroundColor = theme.foregroundSecondary

            return rounds + session
        }
        
        var body: some View {
            VStack(alignment: .center, spacing: 16) {
                Text(attributedTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if rounds <= 5 {
                    HStack(alignment: .center, spacing: 4) {
                        ForEach(0..<rounds) { round in
                            Text("\(Int(timeInterval / 60))")
                                .font(.caption2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .padding(.init(top: 4, leading: 4, bottom: 4, trailing: 4))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(theme.surfacePrimary, in: RoundedRectangle(cornerRadius: 8))
                            if round != rounds - 1 {
                                BreakChip(breakDuration: breakDuration)
                            }
                        }
                    }
                } else {
                    HStack(alignment: .center, spacing: 4) {
                        ForEach(0..<rounds) { round in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(theme.surfacePrimary)
                                .frame(maxWidth: .infinity)
                            if round != rounds - 1 {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(theme.surfaceTertiary)
                                    .stroke(theme.outlinePrimary, style: .init(lineWidth: 1, lineCap: .round, lineJoin: .round, dash: [2, 4], dashPhase: 0.5))
                                    .frame(width: 8, alignment: .center)
                            }
                        }
                    }
                }
            }
        }
        
        private struct BreakChip: View {
            
            @Environment(\.theme) var theme
            let breakDuration: TimeInterval
            
            var body: some View {
                Text("\(Int(breakDuration / 60))")
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
                    .padding(.init(top: 4, leading: 4, bottom: 4, trailing: 4))
                    .background(alignment: .center, content: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.surfaceTertiary)
                            .stroke(theme.outlinePrimary, style: .init(lineWidth: 1, lineCap: .round, lineJoin: .round, dash: [2, 4], dashPhase: 0.5))
                    })
            }
        }
    }
    
    
    private struct ConfigurationRow: View {
        
        @Environment(\.theme) var theme
        
        enum Config {
            case appBlock(FamilyActivitySelection)
            case alarm(FocusSessionAlarmOption)
            
            var icon: SFSymbol {
                switch self {
                case .appBlock:
                    return .iphoneSlash
                case .alarm:
                    return .alarmWavesLeftAndRightFill
                }
            }
            
            var title: String {
                switch self {
                case .appBlock:
                    return "App Block"
                case .alarm:
                    return "Alarm"
                }
            }
            
            var content: String {
                switch self {
                case .appBlock(let appBlock):
                    if appBlock.isEmpty {
                        return "None"
                    } else {
                        return "\(appBlock.applications.count) Apps \(String.separator) \(appBlock.categories.count) Categories \(String.separator) \(appBlock.webDomains.count) Web Domains"
                    }
                case .alarm(let alarmOption):
                    switch alarmOption {
                    case .off:
                        return "Off"
                    case .endOfSession:
                        return "End of Session"
                    case .betweenSessions:
                        return "Between Sesssions"
                    @unknown default:
                        return ""
                    }
                }
            }
        }
        
        let config: Config
        
        var body: some View {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemSymbol: config.icon)
                    .font(.caption2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(config.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.foregroundSecondary)
                    
                    Text(config.content)
                        .font(.subheadline)
                        .foregroundStyle(theme.foregroundPrimary)
                }
            }
            .padding(.init(top: 12, leading: 12, bottom: 12, trailing: 12))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.backgroundSecondary, in: .rect)
        }
    }
    
    
    // MARK: - Shape
    
    struct DashLine: Shape {
        nonisolated func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: .init(x: rect.minX, y: rect.midY))
                path.addLine(to: .init(x: rect.maxX, y: rect.midY))
            }
            .strokedPath(.init(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [2, 4], dashPhase: 0.5))
        }
    }
}

#Preview {
    ScrollView {
        VStack(alignment: .leading, spacing: 12) {
            RoutineDetailFocusSessionCard(config: .init(timeInterval: 45 * 60, breakDuration: 15 * 60, appBlockSelection: .init(), focusSessionType: .pomodoro(currentIndex: 0, total: 6), alarm: .betweenSessions))
            RoutineDetailFocusSessionCard(config: .init(timeInterval: 45 * 60, breakDuration: 15 * 60, appBlockSelection: .init(), focusSessionType: .pomodoro(currentIndex: 0, total: 5), alarm: .betweenSessions))
            RoutineDetailFocusSessionCard(config: .init(timeInterval: 45 * 60, breakDuration: 15 * 60, appBlockSelection: .init(), focusSessionType: .classic, alarm: .endOfSession))
            
        }
        .padding(.horizontal, 16)        
    }
}
