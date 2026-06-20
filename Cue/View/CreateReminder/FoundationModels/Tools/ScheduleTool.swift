//
//  ScheduleTool.swift
//  Kyu
//
//  Created by Krishna Venkatramani on 16/06/2026.
//

import Foundation
import FoundationModels

struct ScheduleTool: Tool {
    
    var name: String = "Schedule Tool"
    var description: String = "You can use this tool recognize the schedule at which you want your reminders"
    
    var includesSchemaInInstructions: Bool = true
    
    @Generable
    struct Arguments {
        @Guide(description: "Frequency (in week count) of the schedule, eg. `1` for every week, '0' when frequest isn't mentioned")
        let frequency: Int
        
        @Guide(description: "Day of the week of the schedule, eg. `0` for Sunday or `6` for Sunday")
        let weekday: Int
        
        @Guide(description: "Hour of the schedule, eg. `5` in `5:30 PM` or `17` in `17:30")
        let hour: Int
        
        @Guide(description: "Minute(s) of the schedule, eg. `30` in `5:30 PM` or `30` in `17:30")
        let minutes: Int
    }
    
    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        print("(DEBUG) This is the recognized schedule: \nfrequency:\(arguments.frequency)\nweekday:\(arguments.weekday)\nhour:\(arguments.hour)\nminutes:\(arguments.minutes)")
//        return GeneratedContent(arguments)
        return Prompt("""
            This is the recognized schedule: \nfrequency:\(arguments.frequency)\nweekday:\(arguments.weekday)\nhour:\(arguments.hour)\nminutes:\(arguments.minutes)")
            use this to create the reminder witht his schedule.
            """)
    }
}
