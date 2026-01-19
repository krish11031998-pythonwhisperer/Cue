//
//  CreateReminderViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 18/01/2026.
//

import SwiftUI
import VanorUI

@Observable
class CreateReminderViewModel {
    
    enum Presentation: String, Identifiable, CaseIterable {
        case alarmAt = "Alarm At"
        case duration = "Duration"
        case date = "Date"
        
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
    
    struct Task {
        let title: String
    }
    
    var reminderTitle: String = ""
    var snoozeDuration: Double = 15
    var date: Date = .now
    var timeDate: Date = .now
    var time: Time = .init(.now)
    var tasks: [Task] = []
    var presentation: Presentation? = nil
    
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
        }
    }
    
    var taskViewModels: [ReminderTaskView.Model] {
        var models: [ReminderTaskView.Model] = []
        for(index, task) in tasks.enumerated() {
            let viewType = ReminderTaskView.ViewType.displayOnly { [weak self] newTaskName in
                self?.tasks[index] = .init(title: newTaskName)
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
        self.tasks.append(.init(title: "Task #\(count)"))
    }
}
