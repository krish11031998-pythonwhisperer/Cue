//
//  NewCreateReminderViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 23/05/2026.
//

import SwiftUI
import VanorUI
import Model
import CoreData
import FoundationModels

@Observable
class NewCreateReminderViewModel: CreateReminderManager {
    
    
    @ObservationIgnored
    var store: Store
    @ObservationIgnored
    var emojiSession: EmojiSession = .init()
    @ObservationIgnored
    var reminderSubtasksSession: ReminderSubtaskSession = .init()
    @ObservationIgnored
    var suggestionTask: Task<Void, Never>?
    @ObservationIgnored
    var edittingMode: Bool = false
    @ObservationIgnored
    var reminderID: NSManagedObjectID?
    
    var reminderTitle: String = ""
    var snoozeDuration: Double = 15 * 60
    var reminderNotification: ReminderNotification = .notification
    var date: Date = Date()
    var timeDate: Date = .init()
    var tags: [TagModel] = []
    var tasks: [CreateReminderTask] = []
    var scheduleBuilder: Reminder.ScheduleBuilder = .init(.now)
    var icon: Icon = .symbol(SFSymbol.allSymbols.randomElement()!)
    var color: Color = .proSky.baseColor
    var isLoadingSuggestions: Bool = false
    
    init(store: Store) {
        self.store = store
        self.edittingMode = false
        self.reminderID = nil
    }
    
    var theme: LCHColor {
        .init(color: color)
    }
    
    func presentIconSheet() {
    }
}
