//
//  CreateReminderViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 18/01/2026.
//

import SwiftUI
import VanorUI
import Model

@Observable
class CreateReminderViewModel {
    
    enum Presentation: String, Identifiable {
        case alarmAt = "Alarm At"
        case duration = "Duration"
        case date = "Date"
        case symbolAndColor = "Symbol And Color"
        
        var id: String { self.rawValue }
        
        static var allCases: [Presentation] { [.alarmAt, .duration, .date] }
    }
    
    enum FullScreenPresentation: String, Identifiable, CaseIterable {
        case symbolSheet = "symbolSheet"
        
        var id: String { self.rawValue }
    }
    
    struct Time {
        let hour: Int
        let minute: Int
        
        init(hour: Int, minute: Int) {
            self.hour = hour
            self.minute = minute
        }
        
        init(_ date: Date) {
            self.hour = date.hours
            self.minute = date.minutes
        }
        
        var date: Date {
            Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now)!
        }
    }
    
    @ObservationIgnored
    let store: Store
    var reminderTitle: String = ""
    var snoozeDuration: Double = 15
    var date: Date = .now
    var timeDate: Date = .now
    var time: Time = .init(.now)
    var tasks: [CueTask] = []
    var icon: SFSymbol = .bolt
    var color: Color = (Color.proSky.baseColor)
    var presentation: Presentation? = nil
    var fullScreenPresentation: FullScreenPresentation? = nil
    
    init(store: Store) {
        self.store = store
    }
    
    var theme: LCHColor {
        .init(color: color)
    }
    
    // MARK: - Helpers
    
    var durationString: String {
        String.formattedTimelineInterval(snoozeDuration)
    }
    
    var dateString: String {
        if date.startOfDay == Date.now.startOfDay {
            return "Today"
        } else if date == Date.now.tomorrow {
            return "Tomorrow"
        } else {
            return date.dateStringFormatter()
        }
    }
    
    var timeString: String {
        timeDate.timeBuilder()
    }
    
    func buttonTitleForElement(_ presentation: Presentation) -> String {
        switch presentation {
        case .alarmAt:
            timeString
        case .duration:
            durationString
        case .date:
            dateString
        case .symbolAndColor:
            fatalError("No Button with title for \(presentation.rawValue)")
        }
    }
    
    var taskViewModels: [ReminderTaskView.Model] {
        var models: [ReminderTaskView.Model] = []
        for(index, task) in tasks.enumerated() {
            let viewType = ReminderTaskView.ViewType.displayOnly { [weak self] newTaskName in
                self?.tasks[index] = .init(title: newTaskName, icon: "number.circle.fill")
            }
            
            let shape: ReminderTaskView.Shape = index == 0 ? .uneven(.init(topLeading: 16, bottomLeading: 8, bottomTrailing: 8, topTrailing: 16)) : index == tasks.count - 1 ? .uneven(.init(topLeading: 8, bottomLeading: 16, bottomTrailing: 16, topTrailing: 8)) : .roundedRect(8)
            
            let model = ReminderTaskView.Model(taskTitle: task.title,
                                               viewType: viewType,
                                               shape: shape,
                                               action: nil)
            models.append(model)
        }
        return models
    }
    
    
    // MARK: - Methods
    
    func addTask() {
        let count = tasks.count + 1
        self.tasks.append(.init(title: "Task #\(count)", icon: "number.circle.fill"))
    }
    
    func createReminder() {
        store.createReminder(title: reminderTitle,
                             iconName: "tag.circle",
                             date: date,
                             tasks: tasks)
    }
}
