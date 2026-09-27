//
//  RoutineDetailView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 26/09/2026.
//

import SwiftUI
import VanorUI
import Model
import FamilyControls

internal struct RoutineDetailViewSection: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.init(top: 20, leading: 20, bottom: 20, trailing: 20))
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(RowBackground())
            .clipShape(RoundedRectangle(cornerRadius: 32))
    }
}

internal struct RoutineDetailGroupBox: GroupBoxStyle {
    
    enum Style {
        case `default`
        case themed(LCHColor)
    }
    
    let style: Style
    
    func makeBody(configuration: Configuration) -> some View {
        switch style {
        case .default:
            VStack(alignment: .leading, spacing: 12) {
                configuration.label
                configuration.content
            }
            .padding(.init(top: 20, leading: 20, bottom: 20, trailing: 20))
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(RowBackground())
            .clipShape(RoundedRectangle(cornerRadius: 32))
        case .themed(let theme):
            VStack(alignment: .leading, spacing: 12) {
                configuration.label
                configuration.content
            }
            .padding(.init(top: 20, leading: 20, bottom: 20, trailing: 20))
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipped()
            .background(alignment: .center) {
                RoundedRectangle(cornerRadius: 32)
                    .fill(theme.surfaceSecondary)
                    .stroke(theme.outlinePrimary, style: .init(lineWidth: 1))
            }
        }
    }
}


@Observable
@MainActor
class RoutineDetailViewModel {
    
    var routine: ReminderModel
    
    init(_ routine: ReminderModel) {
        self.routine = routine
    }
    
    @ObservationIgnored
    var store: Store?
    
    
    private func deleteRoutine() {
        self.store?.deleteReminder(reminderID: routine.objectId)
    }
    
    
    // MARK: - View Computed Helpers
    
    var steps: [RoutineStepsView.Step] {
        return routine.tasks.map { task in
            return .init(icon: .init(task.icon) ?? .unavailableIcon , title: task.title)
        }
    }
    
    var daysInCalendar: [RoutineCalendarView.Day] {
        let startDate = Date.now.startOfMonth
        let endDate = Date.now.endOfMonth
        var days: [RoutineCalendarView.Day] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let day = RoutineCalendarView.Day(isLogged: .random(), date: currentDate, wasScheduled: .random())
            days.append(day)
            if let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDay
            } else {
                break
            }
        }
        
        return days
    }
    
    var headerConfig: RoutineHeaderView.Config {
        .init(name: routine.title,
              icon: .init(routine.icon) ?? .unavailableIcon,
              color: routine.color,
              time: routine.date,
              nudge: routine.notificationType,
              scheduleString: routine.schedule?.timeScheduleString ?? "",
              tags: routine.tags)
    }
    
    var focusSessionConfig: RoutineDetailFocusSessionCard.Config? {
        guard let focusSession = routine.focusSession else { return nil }
        return .init(timeInterval: focusSession.timerDuration,
                     breakDuration: focusSession.breakDuration,
                     appBlockSelection: focusSession.blockedApps ?? .init(),
                     focusSessionType: focusSession.sessionType == .classic ? .classic : .pomodoro(currentIndex: 0, total: focusSession.sessionCount ?? 0),
                     alarm: focusSession.alarm)
    }
}


struct RoutineDetailView: View {

    @State private var viewModel: RoutineDetailViewModel
    init(routine: ReminderModel) {
        self._viewModel = .init(initialValue: .init(routine))
    }
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .center, spacing: 24) {
                RoutineHeaderView(model: viewModel.headerConfig)
                RoutineStepsView(model: .init(steps: viewModel.steps, color: viewModel.routine.color))
                if let focusSessionConfig = viewModel.focusSessionConfig {
                    RoutineDetailFocusSessionCard(config: focusSessionConfig)
                } else {
                    RoutineDetailCreateFocusCard()
                }
                RoutineCalendarView(model: .init(month: Date.now.month, schedule: nil, calendarDay: viewModel.daysInCalendar, color: viewModel.routine.color))
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .environment(\.theme, .init(color: viewModel.routine.color))
        .background(alignment: .center) {
            Color.cueItBackground
                .ignoresSafeArea()
        }
    }
}

#Preview("RoutineDetail (without FocusSession)") {
    RoutineDetailView(routine: .exampleFive())
}

#Preview("RoutineDetail (with FocusSession)") {
    RoutineDetailView(routine: .exampleSix())
}

#Preview("RoutineDetail (with FocusSession)") {
    RoutineDetailView(routine: .exampleSeven())
}
