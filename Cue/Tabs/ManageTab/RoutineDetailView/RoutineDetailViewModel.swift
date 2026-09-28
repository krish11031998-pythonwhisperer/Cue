//
//  RoutineDetailViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 27/09/2026.
//

import SwiftUI
import VanorUI
import Model
import FamilyControls

@Observable
@MainActor
class RoutineDetailViewModel {
    
    enum Presentation: Identifiable {
        case editRoutine(ReminderModel)
        case createFocusSession(ReminderModel)
        
        var id: String {
            switch self {
            case .editRoutine(let routine):
                return "edit_\(routine.hashValue)"
            case .createFocusSession(let routine):
                return "createFocusSession_\(routine.hashValue)"
            }
        }
    }
    
    var routine: ReminderModel
    var presentation: Presentation? = nil
    var showDeleteAlert: Bool = false

    init(_ routine: ReminderModel) {
        self.routine = routine
    }
    
    @ObservationIgnored
    var store: Store?

    var daysInCalendar: [RoutineCalendarView.Day] = []

    
    func deleteRoutine() {
        self.store?.deleteReminder(reminderID: routine.objectId)
    }
    
    
    // MARK: - Fetch Logs
    
    @concurrent
    func fetchRoutineLogs() async {
        #if targetEnvironment(simulator)
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
        #else
        let calendarDays = await CalendarManager.shared.setupCalendarForCurrentMonth(for: routine)
        let days: [RoutineCalendarView.Day] = calendarDays.map { calendarDay in
                .init(isLogged: !calendarDay.loggedReminders.isEmpty,
                      date: calendarDay.date,
                      wasScheduled: !calendarDay.reminders.isEmpty)
        }
        #endif
        await MainActor.run {
            self.daysInCalendar = days
        }
    }
    
    
    // MARK: - UpdateFocusSession
    
    func updateFocusSession(with newFocusSession: FocusSessionModel) {
        guard let store, let reminderID = routine.objectId else { return }

        let reminder = Reminder.fetch(context: store.viewContext, for: reminderID)
        store.createFocusSession(name: newFocusSession.name,
                                 sessionType: newFocusSession.sessionType,
                                 timerDuration: newFocusSession.timerDuration,
                                 breakDuration: newFocusSession.breakDuration,
                                 blockedApps: newFocusSession.blockedApps,
                                 alarm: newFocusSession.alarm,
                                 sessionCount: newFocusSession.sessionCount,
                                 imageFileName: newFocusSession.imageFileName,
                                 reminder: reminder)

        self.routine = ReminderModel(from: reminder)
    }
    
    
    // MARK: - View Computed Helpers
    
    var steps: [RoutineStepsView.Step] {
        return routine.tasks.map { task in
            return .init(icon: .init(task.icon) ?? .unavailableIcon , title: task.title)
        }
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
