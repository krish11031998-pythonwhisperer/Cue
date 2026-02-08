//
//  AppIntents.swift
//  Model
//
//  Created by Krishna Venkatramani on 08/02/2026.
//

import AlarmKit
import AppIntents

struct RepeatIntent: LiveActivityIntent {
    func perform() throws -> some IntentResult {
        try AlarmManager.shared.countdown(id: UUID(uuidString: alarmID)!)
        return .result()
    }
    
    static var title: LocalizedStringResource = "Repeat"
    static var description = IntentDescription("Repeat a countdown")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    init() {
        self.alarmID = ""
    }
}
