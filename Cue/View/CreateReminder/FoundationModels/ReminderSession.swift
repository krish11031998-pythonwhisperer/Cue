//
//  ReminderSession.swift
//  Cue
//
//  Created by Krishna Venkatramani on 01/03/2026.
//

import FoundationModels
import VanorUI
import Foundation
import SwiftUI
import Model

fileprivate extension Calendar {
    var weekdayIndices: ClosedRange<Int> {
        0...(weekdaySymbols.count - 1)
    }
}

@Generable
struct SuggestedReminderSchedule {
    
    @Generable
    struct Weekday {
        @Guide(description: "Represents the weekday in the week, 0 is first day of the week and \(Calendar.current.weekdaySymbols.count - 1) is last day of the week. This is based on Calendar.current")
        @Guide(.range(Calendar.current.weekdayIndices))
        var weekdayIntValue: Int
    }
    
    @Guide(description: "24-hour clock hour, 0...23")
    var hour: Int
    
    @Guide(description: "Minute, 0...59")
    var minute:Int
    
    @Guide(description: "0 for one-time reminders, otherwise the number of weeks between repetitions")
    var internvalWeek: Int
    
    @Guide(description: "Weekday index based on Calendar.current")
    var weekdays: [Weekday]?
}

@Generable
struct SuggestedReminder {
    @Guide(description: "Title of the reminder")
    var title: String
    
    @Guide(description: "Emoji of the reminder")
    var icon: String
    
    @Guide(description: "Time at which the reminder is set")
    var date: SuggestedReminderSchedule
    
    static var promptExample: String {
        "Reminder me to buy groceries at 7pm every week."
    }
    
    static var promptExampleTwo: String {
        "Nudge me to go to the gym every Monday, Tuesday and Wednesday at 7pm every week."
    }
    
    static var example: SuggestedReminder {
        let date = Date.now.startOfDay
        var components = Calendar.current.dateComponents([.day, .month, .year, .calendar], from: date)
        components.hour = 19
        components.minute = 0
        
        return .init(title: "Buy groceries", icon: "🛒", date: .init(hour: 19, minute: 0, internvalWeek: 0, weekdays: nil))
    }
    
    static var exampleTwo: SuggestedReminder {
        let date = Date.now.startOfDay
        var components = Calendar.current.dateComponents([.day, .month, .year, .calendar], from: date)
        components.hour = 19
        components.minute = 0
        
        return .init(title: "Workout in at Gym", icon: "🏋️", date: .init(hour: 19, minute: 0, internvalWeek: 1, weekdays: [1, 2, 3].map { SuggestedReminderSchedule.Weekday(weekdayIntValue: $0) }))
    }
}

class ReminderGenerator: CueLanguagareModelSession {
    
    enum SessionType {
        case simple
        case withTools
        
        var tools: [any Tool] {
            switch self {
            case .simple:
                return []
            case .withTools:
//                return [EmojiTool(), ScheduleTool()]
                return [EmojiTool()]
//                return [ScheduleTool()]
            }
        }
        
        var instruction: Instructions {
            switch self {
            case .simple:
                    .init {
                        """
                        You are an expert at building routines and you will help the user build routines that they want to cultivate.
                        You should be able to recognize the activity that the user mentions in their prompt.
                        
                        Core rule:
                        - If the user does NOT mention repetition → create a one
                        - internvalWeek = 0
                        - weekdays = nil
                        - If the user mentions repetition → create a recurring reminders
                        
                        Title:
                        - Short, natural action (no schedule details)
                        
                        Time:
                        - Use provided time or infer reasonable defaults
                        
                        Recurring:
                        - Map the recurring weeks → intervalWeek = N where N is number of weeks.
                        - Map weekdays when mentioned
                        
                        Input:
                        \(SuggestedReminder.promptExample)
                        Output:
                        """
                        SuggestedReminder.example
                        
                        """
                        here is an example with reccuring reminders where the intervalWeeks is recognized
                        Input:
                        \(SuggestedReminder.promptExampleTwo)
                        Output:
                        """
                        SuggestedReminder.exampleTwo
                    }
            case .withTools:
                    .init {
                        """
                        You are a reminder extraction assistant.
                        
                        Return exactly one `SuggestedReminder` from the user’s request.
                        Do not explain anything.
                        
                        Core rule:
                        - If the user does NOT mention repetition → create a one-time reminder.
                        - internvalWeek = 0
                        - weekdays = nil
                        - If the user mentions repetition → create a recurring reminder.
                        
                        Title:
                        - Short, natural action (no schedule details)
                        
                        Time:
                        - Use provided time or infer reasonable defaults
                        
                        Recurring:
                        - weekly / every week → internvalWeek = 1
                        - every N weeks → internvalWeek = N
                        - Map weekdays when mentioned
                        
                        ALWAYS USE EmojiTool to get suitable emoji for the reminder
                        
                        Examples:
                        
                        Input:
                        \(SuggestedReminder.promptExample)
                        Output:
                        """
                        SuggestedReminder.example
                        """
                        Input:
                        \(SuggestedReminder.promptExampleTwo)
                        Output:
                        """
                        SuggestedReminder.exampleTwo
                    }
            }
        }
    }
    
    let sessionType: SessionType
    
    init(sessionType: SessionType = .simple) {
        self.sessionType = sessionType
        let session = LanguageModelSession(model: .default, tools: sessionType.tools, instructions: {
            sessionType.instruction
        })
        session.prewarm()
        super.init(session: session)
    }
    
    func suggestReminder(for description: String) async -> SuggestedReminder? {
        await generate(for: description)
    }
}

fileprivate struct TestView: View {
    
    @State private var loading: Bool = false
    @State private var reminderSearch: String = ""
    @State private var reminders: [ReminderModel] = []
    private let suggestionModel: ReminderGenerator = .init(sessionType: .simple)
    
    var examples: [String] {
        [
            "Remind me to buy groceries at 7pm tomorrow.",
            "I want to have healthy lunch this afternoon",
            "Submit my homework this evening",
            "Go running tomorrow at during the afternoon",
            "Clean apartment on Wednesday evening every week",
            "Go Running on Tuesday morning every week"
        ]
    }
    
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(examples, id: \.self) { example in
                        Button {
                            self.reminderSearch = example
                        } label: {
                            Text(example)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                                .padding(.init(top: 6, leading: 8, bottom: 6, trailing: 8))
                                .opacity(reminderSearch == example && loading ? 0 : 1)
                                .overlay {
                                    if reminderSearch == example && loading {
                                        ProgressView()
                                            .tint(Color.proSky.invertedForegroundPrimary)
                                    }
                                }
                        }
                        .tint(Color.proSky.baseColor)
                        .buttonStyle(.glassProminent)
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(reminders) { reminder in
                        ReminderView(model: .init(title: reminder.title, icon: .init(reminder.icon)!, theme: Color.proSky, time: reminder.schedule?.timeScheduled ?? .now, state: .display, tags: [], logReminder: nil, deleteReminder: nil))
                    }
                }
            }
            .padding(.all, 12)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .task(id: reminderSearch) { @MainActor in
            guard !reminderSearch.isEmpty else { return }
            self.loading = true
            let suggestedReminder = await suggestionModel.suggestReminder(for: reminderSearch)
            
            self.loading = false
            print("(DEBUG) reminder:", suggestedReminder)
            if let suggestedReminder {
                let reminder = ReminderModel(notificationType: .notification, title: suggestedReminder.title, icon: .init(symbol: nil, emoji: suggestedReminder.icon), date: .now, snoozeDuration: .zero, tasks: [], tags: [], schedule: .init(hour: suggestedReminder.date.hour, minute: suggestedReminder.date.minute, intervalWeeks: suggestedReminder.date.internvalWeek, weekdays: nil, calendarDates: nil), colorName: Color.sky.assetName)
                self.reminders.append(reminder)
            }
        }
    }
    
}


#Preview {
    TestView()
}
