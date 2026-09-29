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

@Generable
struct SuggestedReminderSchedule {

    /// The model picks the weekday by name (copied from the user's words) instead of a number,
    /// so it can't shift days by one; `weekdayIntValue` maps it to the `Calendar.weekday` component.
    @Generable
    enum Weekday: CaseIterable {
        case sunday, monday, tuesday, wednesday, thursday, friday, saturday

        /// `Calendar.weekday` component value: 1 is Sunday ... 7 is Saturday.
        var weekdayIntValue: Int {
            Self.allCases.firstIndex(of: self)! + 1
        }
    }

    // Properties are generated in declaration order: repeat → days → date → time.

    @Guide(description: "0 if the reminder does not repeat, otherwise the number of weeks between repetitions", .range(0...4))
    var intervalWeek: Int

    @Guide(description: "Only the days the user names for a repeating reminder, nil for one-time reminders")
    var weekdays: [Weekday]?

    @Guide(description: "Days from today until the reminder, 0 is today and 1 is tomorrow", .range(0...90))
    var daysFromToday: Int

    @Guide(description: "24-hour clock hour", .range(0...23))
    var hour: Int

    @Guide(description: "Minute", .range(0...59))
    var minute: Int
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
        "Remind me to call mom tomorrow at 6pm"
    }

    static var promptExampleTwo: String {
        "Nudge me to go to the gym every Tuesday, Thursday and Friday at 7am"
    }

    static var example: SuggestedReminder {
        .init(title: "Call mom", icon: "📞", date: .init(intervalWeek: 0, weekdays: nil, daysFromToday: 1, hour: 18, minute: 0))
    }

    static var exampleTwo: SuggestedReminder {
        .init(title: "Go to the gym", icon: "🏋️", date: .init(intervalWeek: 1, weekdays: [.tuesday, .thursday, .friday], daysFromToday: 0, hour: 7, minute: 0))
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
                        You turn one sentence into exactly one reminder.

                        title: short action, no schedule details.
                        icon: exactly one emoji.

                        intervalWeek:
                        - No repeat words → 0 and weekdays = nil.
                        - "every week", "every <day>", "daily", "weekdays" → 1.
                        - "every other week", "every 2 weeks" → 2. "every N weeks" → N.
                        - "in 2 weeks" is a date, NOT a repeat.

                        weekdays: ONLY the days the user names. "daily" → all 7 days.

                        daysFromToday: today = 0, tomorrow = 1, a named day → its number in the Days list, "in N weeks" → N × 7.

                        Time: use the given time. If none: morning 9:00, afternoon 14:00, evening 18:00, night 21:00, otherwise 9:00.

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

    override var tools: [any Tool] {
        sessionType.tools
    }

    /// Extraction needs the same answer every time, not a creative one.
    override var generationOptions: GenerationOptions? {
        GenerationOptions(sampling: .greedy)
    }

    /// The examples in the instructions already show every field.
    override var includesSchemaInPrompt: Bool {
        false
    }

    override var usesFreshSessionPerRequest: Bool {
        true
    }

    init(sessionType: SessionType = .simple) {
        self.sessionType = sessionType
        let session = LanguageModelSession(model: .default, tools: sessionType.tools, instructions: {
            sessionType.instruction
        })
        session.prewarm(promptPrefix: Prompt(CueLanguagareModelSession.promptPrefix))
        super.init(session: session)
    }

    func suggestReminder(for description: String) async -> SuggestedReminder? {
        let namedSchedule = NamedSchedule(in: description)
        // The Days list is only needed to date a one-time reminder on a named day ("on Friday").
        let prompt = namedSchedule.namesDay && !namedSchedule.repeats ? "\(description)\n\(dateContext)" : description
        guard var reminder: SuggestedReminder = await generate(for: prompt) else { return nil }

        // The small model sometimes misses a repeat or picks the wrong weekdays, while the words
        // the user typed are always right, so they win whenever they're recognized.
        if reminder.date.intervalWeek == 0, namedSchedule.repeats {
            reminder.date.intervalWeek = 1
        }
        if reminder.date.intervalWeek > 0, !namedSchedule.weekdays.isEmpty {
            reminder.date.weekdays = SuggestedReminderSchedule.Weekday.allCases.filter(namedSchedule.weekdays.contains)
        }
        return reminder
    }

    /// Today's date and the offsets of the next 7 days, built per prompt so it's never stale.
    /// The model looks up "on Friday" as a `daysFromToday` value instead of doing date arithmetic.
    /// English symbols are used so they match the instructions and the `Weekday` cases.
    private var dateContext: String {
        let locale = Locale(identifier: "en_US_POSIX")
        var calendar = Calendar.current
        calendar.locale = locale
        let today = Date.now
        let upcomingDays = (1...7).compactMap { offset -> String? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
            return "\(calendar.shortWeekdaySymbols[calendar.component(.weekday, from: day) - 1])=\(offset)"
        }
        return """
            Today: \(today.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(locale)))
            Days: \(upcomingDays.joined(separator: ", "))
            """
    }
}

/// The weekdays and repeat words in the user's own sentence, read without the model.
/// English only: for other languages nothing is recognized and the model's answer is kept.
fileprivate struct NamedSchedule {

    typealias Weekday = SuggestedReminderSchedule.Weekday

    private(set) var weekdays: Set<Weekday> = []
    /// A specific day is named, e.g. "Friday" (not "weekdays" or "daily").
    private(set) var namesDay = false
    /// e.g. "every Tuesday", "Tuesdays", "every week", "daily", "weekdays".
    private(set) var repeats = false

    private static let rangeWords: Set<String> = ["to", "through", "thru", "till", "until", "-"]

    init(in text: String) {
        let words = Self.words(in: text)
        for (index, word) in words.enumerated() {
            let followsEvery = index > 0 && ["every", "each"].contains(words[index - 1])

            if let day = Self.weekday(named: word) {
                namesDay = true
                repeats = repeats || followsEvery || word.hasSuffix("days")
                // "Monday to Friday", "Mon-Fri"
                if index + 2 < words.count, Self.rangeWords.contains(words[index + 1]),
                   let lastDay = Self.weekday(named: words[index + 2]) {
                    weekdays.formUnion(Self.days(from: day, through: lastDay))
                } else {
                    weekdays.insert(day)
                }
                continue
            }

            switch word {
            case "daily", "everyday":
                weekdays.formUnion(Weekday.allCases)
                repeats = true
            case "day" where followsEvery:
                weekdays.formUnion(Weekday.allCases)
                repeats = true
            case "weekly":
                repeats = true
            case "week" where followsEvery:
                repeats = true
            case "weekdays", "weekday":
                weekdays.formUnion([.monday, .tuesday, .wednesday, .thursday, .friday])
                repeats = repeats || followsEvery || word == "weekdays"
            case "weekends", "weekend":
                // "this weekend" is a date, "weekends" or "every weekend" repeats.
                weekdays.formUnion([.saturday, .sunday])
                repeats = repeats || followsEvery || word == "weekends"
            default:
                break
            }
        }
    }

    /// Lowercased words, with dashes kept as their own word for ranges like "mon-fri".
    private static func words(in text: String) -> [String] {
        var words: [String] = []
        var word = ""
        for character in text.lowercased() {
            if character.isLetter {
                word.append(character)
                continue
            }
            if !word.isEmpty {
                words.append(word)
                word = ""
            }
            if character == "-" || character == "–" {
                words.append("-")
            }
        }
        if !word.isEmpty {
            words.append(word)
        }
        return words
    }

    /// "Sun" and "Sat" are left out on purpose, they're common words ("in the sun").
    private static func weekday(named word: String) -> Weekday? {
        switch word {
        case "sunday", "sundays":
            return .sunday
        case "monday", "mondays", "mon":
            return .monday
        case "tuesday", "tuesdays", "tue", "tues":
            return .tuesday
        case "wednesday", "wednesdays", "wed", "weds":
            return .wednesday
        case "thursday", "thursdays", "thu", "thur", "thurs":
            return .thursday
        case "friday", "fridays", "fri":
            return .friday
        case "saturday", "saturdays":
            return .saturday
        default:
            return nil
        }
    }

    /// Every day from `firstDay` through `lastDay`, wrapping past Saturday ("Friday to Monday").
    private static func days(from firstDay: Weekday, through lastDay: Weekday) -> [Weekday] {
        let allDays = Weekday.allCases
        let first = allDays.firstIndex(of: firstDay)!
        let last = allDays.firstIndex(of: lastDay)!
        let count = (last - first + allDays.count) % allDays.count + 1
        return (0..<count).map { allDays[(first + $0) % allDays.count] }
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
                        ReminderView(model: .init(title: reminder.title,
                                                  icon: .init(reminder.icon)!,
                                                  lightColor: Color("sky").resolved(for: .light),
                                                  darkColor: Color("sky").resolved(for: .dark),
                                                  time: reminder.schedule?.timeScheduled ?? .now,
                                                  state: .display,
                                                  tags: [],
                                                  logReminder: nil,
                                                  deleteReminder: nil))
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
                let reminder = ReminderModel(notificationType: .notification, title: suggestedReminder.title, icon: .init(symbol: nil, emoji: suggestedReminder.icon), date: .now, snoozeDuration: .zero, tasks: [], tags: [], schedule: .init(hour: suggestedReminder.date.hour, minute: suggestedReminder.date.minute, intervalWeeks: suggestedReminder.date.intervalWeek, weekdays: nil, calendarDates: nil), colorName: Color.sky.assetName, focusSession: nil)
                self.reminders.append(reminder)
            }
        }
    }
    
}


#Preview {
    TestView()
}
