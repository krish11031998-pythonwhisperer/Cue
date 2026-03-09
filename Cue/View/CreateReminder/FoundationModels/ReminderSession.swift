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
    
    @Guide(description: "Icon of the reminder")
    @Guide(.anyOf(EmojiCategory.activity.emojis.map(\.char)))
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
        
        return .init(title: "Workout in at Gym", icon: "🏋️‍♀️", date: .init(hour: 17, minute: 0, internvalWeek: 1, weekdays: [1, 2, 3].map { SuggestedReminderSchedule.Weekday(weekdayIntValue: $0) }))
    }    
}

class ReminderGenerator {
    
    var session: LanguageModelSession
    
    init() {
        session = .init {
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
            """
            If no repetition is mentioned, return a one-time reminder.

            Return only a `SuggestedReminder`.
            """
        }
    }
    
    nonisolated func suggestReminder(for description: String) async -> SuggestedReminder? {
        do {
            let prompt = Prompt("Create an reminder of this description: \(description)")
            let tasks = try await session.respond(to: prompt,
                                                  generating: SuggestedReminder.self,
                                                  includeSchemaInPrompt: true)
            guard !Task.isCancelled else { return nil }
            return tasks.content
        } catch let error as LanguageModelSession.GenerationError {
            switch error {
            case .exceededContextWindowSize:
                await createNewContextualSession()
                return await suggestReminder(for: description)
            case .assetsUnavailable:
                print("asset Unavailable")
            case .guardrailViolation:
                print("guardrailViolation")
            case .unsupportedGuide:
                print("unsupportedGuide")
            case .unsupportedLanguageOrLocale:
                print("unsupportedLanguageOrLocale")
            case .decodingFailure:
                print("decodingFailure")
            case .rateLimited:
                print("rateLimited")
            case .concurrentRequests:
                print("concurrentRequests")
            case .refusal:
                print("concurrentRequests")
            @unknown default:
                break
            }
        } catch {
            print("(DEBUG) There was an error: \(error.localizedDescription)")
        }
        return nil
    }
    
    @MainActor
    func createNewContextualSession() {
        let allEntries = session.transcript
        let condensedEntries = [allEntries.first, allEntries.last].compactMap { $0 }
        let condensedTranscript = Transcript(entries: condensedEntries)
        let newSession = LanguageModelSession(transcript: condensedTranscript)
        newSession.prewarm()
        self.session = newSession
    }
}

fileprivate struct TestView: View {
    
    @State private var loading: Bool = false
    @State private var reminderSearch: String = ""
    private let suggestionModel: ReminderGenerator = .init()
    
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
            }
            .padding(.all, 12)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .task(id: reminderSearch) { @MainActor in
            guard !reminderSearch.isEmpty else { return }
            self.loading = true
            let reminder = await suggestionModel.suggestReminder(for: reminderSearch)
            self.loading = false
            print("(DEBUG) reminder:", reminder)
            if let weekdays = reminder?.date.weekdays {
                weekdays.forEach { weekdayValue in
                    print("\(Calendar.current.weekdaySymbols[weekdayValue.weekdayIntValue])")
                }
            }
        }
    }
    
}


#Preview {
    TestView()
}
