//
//  OnboardingViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 29/09/2026.
//

import SwiftUI
import UserNotifications
import FoundationModels
import SFSafeSymbols
import Model

// MARK: - Step

enum OnboardingStep: Int, CaseIterable, Identifiable {
    case welcome
    case goals
    case rhythm
    case firstReminder
    case notifications
    case focus
    case ready

    var id: Int { rawValue }

    var next: OnboardingStep? {
        .init(rawValue: rawValue + 1)
    }

    var previous: OnboardingStep? {
        .init(rawValue: rawValue - 1)
    }

    /// Number of progress dots. `ready` has no dot of its own — it fills them all.
    static var progressCount: Int {
        allCases.count - 1
    }

    var progressIndex: Int {
        min(rawValue, Self.progressCount - 1)
    }

    var showsBack: Bool {
        self != .welcome && self != .ready
    }

    var showsSkip: Bool {
        self != .ready
    }
}

// MARK: - Goal

enum OnboardingGoal: String, CaseIterable, Identifiable {
    case work
    case health
    case study
    case home
    case money

    var id: String { rawValue }

    var title: String {
        switch self {
        case .work:
            return "Work & deadlines"
        case .health:
            return "Health & movement"
        case .study:
            return "Study & deep work"
        case .home:
            return "Home & errands"
        case .money:
            return "Money & bills"
        }
    }

    /// Name of the tag the first reminder is filed under.
    var tagName: String {
        switch self {
        case .work:
            return "Work"
        case .health:
            return "Health"
        case .study:
            return "Study"
        case .home:
            return "Home"
        case .money:
            return "Money"
        }
    }

    /// Asset name from the reminder palette in `Colors.xcassets`.
    var colorName: String {
        switch self {
        case .work:
            return "perwinkle"
        case .health:
            return "mint"
        case .study:
            return "lavender"
        case .home:
            return "honey"
        case .money:
            return "peach"
        }
    }

    var color: Color {
        Color(colorName)
    }

    var symbol: SFSymbol {
        switch self {
        case .work:
            return .briefcaseFill
        case .health:
            return .figureRun
        case .study:
            return .bookFill
        case .home:
            return .houseFill
        case .money:
            return .creditcardFill
        }
    }

    var suggestions: [OnboardingReminderSuggestion] {
        switch self {
        case .work:
            return [
                .init(title: "Standup at 9:30 AM", reminderTitle: "Standup", emoji: "📋", hour: 9, minute: 30, weekdays: [2, 3, 4, 5, 6], repeats: true, goal: self),
                .init(title: "Plan tomorrow", reminderTitle: "Plan tomorrow", emoji: "🗒️", hour: 17, minute: 30, weekdays: [2, 3, 4, 5, 6], repeats: true, goal: self)
            ]
        case .health:
            return [
                .init(title: "Gym after work", reminderTitle: "Gym after work", emoji: "🏋️", hour: 18, minute: 30, weekdays: [3], repeats: true, goal: self),
                .init(title: "Drink water", reminderTitle: "Drink water", emoji: "💧", hour: 11, minute: 0, weekdays: Set(1...7), repeats: true, goal: self)
            ]
        case .study:
            return [
                .init(title: "Deep work block", reminderTitle: "Deep work block", emoji: "📚", hour: 10, minute: 0, weekdays: [2, 3, 4, 5, 6], repeats: true, goal: self)
            ]
        case .home:
            return [
                .init(title: "Grocery run Saturday", reminderTitle: "Grocery run", emoji: "🛒", hour: 10, minute: 0, weekdays: [7], repeats: true, goal: self)
            ]
        case .money:
            return [
                .init(title: "Pay rent Friday", reminderTitle: "Pay rent", emoji: "💸", hour: 9, minute: 0, weekdays: [6], repeats: false, goal: self)
            ]
        }
    }
}

// MARK: - Reminder Suggestion

struct OnboardingReminderSuggestion: Hashable, Identifiable {
    /// Chip label.
    let title: String
    let reminderTitle: String
    let emoji: String
    let hour: Int
    let minute: Int
    /// `Calendar` weekday components (1 is Sunday).
    let weekdays: Set<Int>
    let repeats: Bool
    let goal: OnboardingGoal?

    var id: String { title }

    static let callHome: OnboardingReminderSuggestion = .init(title: "Call mum Sunday", reminderTitle: "Call mum", emoji: "☎️", hour: 17, minute: 0, weekdays: [1], repeats: false, goal: nil)
}

// MARK: - Reminder Draft

struct OnboardingReminderDraft: Hashable {
    /// The text the draft was built from, so edits to the field invalidate it.
    let sourceText: String
    let title: String
    let emoji: String
    let hour: Int
    let minute: Int
    let weekdays: Set<Int>?
    let repeats: Bool
    let goal: OnboardingGoal?
    let readByCueAI: Bool

    var date: Date {
        Self.nextDate(hour: hour, minute: minute, weekdays: weekdays)
    }

    var scheduleBuilder: Reminder.ScheduleBuilder {
        .init(hour: hour,
              minute: minute,
              intervalWeek: repeats ? 1 : nil,
              weekdays: repeats ? weekdays : nil,
              dates: nil)
    }

    /// e.g. "Tue 6:30 PM", "Weekdays 9:30 AM", "Every day 11:00 AM".
    var scheduleDescription: String {
        let time = date.formatted(date: .omitted, time: .shortened)
        guard repeats, let weekdays else {
            return date.formatted(.dateTime.weekday(.abbreviated).hour().minute())
        }

        if weekdays == Set(1...7) {
            return "Every day \(time)"
        } else if weekdays == Set(2...6) {
            return "Weekdays \(time)"
        }
        
        let symbols = Calendar.current.shortWeekdaySymbols
        let days = weekdays.sorted()
            .filter { symbols.indices.contains($0 - 1) }
            .map { symbols[$0 - 1] }
            .joined(separator: ", ")
        return "\(days) \(time)"
    }

    var repeatDescription: String {
        repeats ? "Repeats weekly" : "One-time"
    }

    init(sourceText: String, title: String, emoji: String, hour: Int, minute: Int, weekdays: Set<Int>?, repeats: Bool, goal: OnboardingGoal?, readByCueAI: Bool) {
        self.sourceText = sourceText
        self.title = title
        self.emoji = emoji
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
        self.repeats = repeats
        self.goal = goal
        self.readByCueAI = readByCueAI
    }

    init(suggestion: OnboardingReminderSuggestion) {
        self.init(sourceText: suggestion.title,
                  title: suggestion.reminderTitle,
                  emoji: suggestion.emoji,
                  hour: suggestion.hour,
                  minute: suggestion.minute,
                  weekdays: suggestion.weekdays,
                  repeats: suggestion.repeats,
                  goal: suggestion.goal,
                  readByCueAI: false)
    }

    /// Next time `hour:minute` falls on one of `weekdays` (or on any day when `weekdays` is empty).
    static func nextDate(hour: Int, minute: Int, weekdays: Set<Int>?, after now: Date = .now) -> Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        guard let weekdays, !weekdays.isEmpty else {
            return calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) ?? now
        }

        return weekdays
            .compactMap { weekday -> Date? in
                var weekdayComponents = components
                weekdayComponents.weekday = weekday
                return calendar.nextDate(after: now, matching: weekdayComponents, matchingPolicy: .nextTime)
            }
            .min() ?? now
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class OnboardingViewModel {

    enum NotificationStatus {
        case notDetermined
        case granted
        case denied
    }

    /// Sendable copy of what cue:ai read out of the typed sentence.
    struct InterpretedReminder: Sendable {
        let title: String
        let emoji: String
        let hour: Int
        let minute: Int
        let intervalWeek: Int
        let weekdays: Set<Int>
    }

    static let dayStartOptions: [Int] = Array(stride(from: 4 * 60, through: 12 * 60, by: 30))
    static let windDownOptions: [Int] = Array(stride(from: 19 * 60, through: 25 * 60, by: 30))

    private(set) var step: OnboardingStep = .welcome

    // Goals
    var selectedGoals: Set<OnboardingGoal> = []

    // Rhythm — minutes after midnight. Wind down may run past midnight (> 1440).
    var dayStartMinutes: Int = 7 * 60 + 30
    var windDownMinutes: Int = 22 * 60 + 30
    private(set) var rhythmConfirmed: Bool = false

    // First reminder
    var reminderText: String = ""
    private(set) var draft: OnboardingReminderDraft?
    private(set) var isInterpreting: Bool = false
    private(set) var createdReminder: OnboardingReminderDraft?

    // Notifications
    private(set) var notificationStatus: NotificationStatus = .notDetermined
    private(set) var isRequestingNotifications: Bool = false

    // Focus
    var focusDemoCompleted: Bool = false

    let store: Store
    private let reminderGenerator: ReminderGenerator?

    init(store: Store) {
        self.store = store
        self.reminderGenerator = SystemLanguageModel.cueAIAvailability == .available ? .init(sessionType: .simple) : nil
    }

    // MARK: - Navigation

    func advance() {
        guard let next = step.next else { return }
        move(to: next)
    }

    func goBack() {
        guard step.showsBack, let previous = step.previous else { return }
        move(to: previous)
    }

    /// Skips the rest of setup and lands on the summary.
    func skip() {
        move(to: .ready)
    }

    private func move(to newStep: OnboardingStep) {
        step = newStep
        if newStep == .ready {
            completeOnboarding()
        }
    }

    private func completeOnboarding() {
        let defaults = CueUserDefaultsManager.shared
        defaults[.onboardingGoals] = orderedGoals.map(\.rawValue)
        if rhythmConfirmed {
            defaults[.dayStartMinutes] = dayStartMinutes
            defaults[.windDownMinutes] = windDownMinutes
        }
        defaults[.hasShowOnboarding] = true
    }

    // MARK: - Goals

    var orderedGoals: [OnboardingGoal] {
        OnboardingGoal.allCases.filter(selectedGoals.contains)
    }

    func toggle(_ goal: OnboardingGoal) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }

    // MARK: - Rhythm

    func confirmRhythm() {
        rhythmConfirmed = true
        advance()
    }

    static func timeString(minutes: Int) -> String {
        let date = Calendar.current.date(bySettingHour: (minutes / 60) % 24, minute: minutes % 60, second: 0, of: .now) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }

    // MARK: - First Reminder

    /// Seeded from the chosen goals; falls back to a spread across every goal.
    var suggestions: [OnboardingReminderSuggestion] {
        let goals = orderedGoals.isEmpty ? [.work, .health, .money] : orderedGoals
        let firstPicks = goals.compactMap(\.suggestions.first)
        let rest = goals.flatMap { $0.suggestions.dropFirst() }
        return Array((firstPicks + rest + [.callHome]).prefix(4))
    }

    func select(_ suggestion: OnboardingReminderSuggestion) {
        reminderText = suggestion.title
        draft = .init(suggestion: suggestion)
    }

    /// Drops a draft that no longer matches what's in the field.
    func reminderTextChanged() {
        guard let draft, draft.sourceText != reminderText else { return }
        self.draft = nil
    }

    /// Turns the typed sentence into a draft — through cue:ai when the device supports it,
    /// otherwise at the start of the user's day.
    func interpretTypedReminder() async {
        let text = reminderText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, draft?.sourceText != reminderText else { return }

        let sourceText = reminderText
        let goal = orderedGoals.first

        if reminderGenerator != nil {
            isInterpreting = true
            let interpreted = await interpret(text)
            isInterpreting = false
            // The field moved on while cue:ai was thinking.
            guard sourceText == reminderText else { return }

            if let interpreted {
                draft = .init(sourceText: sourceText,
                              title: interpreted.title,
                              emoji: interpreted.emoji,
                              hour: interpreted.hour,
                              minute: interpreted.minute,
                              weekdays: interpreted.weekdays.isEmpty ? nil : interpreted.weekdays,
                              repeats: interpreted.intervalWeek > 0,
                              goal: goal,
                              readByCueAI: true)
                return
            }
        }

        draft = .init(sourceText: sourceText,
                      title: text,
                      emoji: "🔔",
                      hour: dayStartMinutes / 60,
                      minute: dayStartMinutes % 60,
                      weekdays: nil,
                      repeats: false,
                      goal: goal,
                      readByCueAI: false)
    }

    @concurrent
    nonisolated private func interpret(_ text: String) async -> InterpretedReminder? {
        guard let reminderGenerator,
              let suggested = await reminderGenerator.suggestReminder(for: text) else {
            return nil
        }
        // The model is only *guided* towards valid ranges, so clamp before persisting.
        let weekdays = Set(suggested.date.weekdays?.map(\.weekdayIntValue).filter { (1...7).contains($0) } ?? [])
        return .init(title: suggested.title,
                     emoji: suggested.icon,
                     hour: min(max(suggested.date.hour, 0), 23),
                     minute: min(max(suggested.date.minute, 0), 59),
                     intervalWeek: max(suggested.date.intervalWeek, 0),
                     weekdays: weekdays)
    }

    func createFirstReminder() {
        guard let draft else { return }
        // Going back and pressing create again shouldn't duplicate the reminder.
        guard createdReminder != draft else {
            advance()
            return
        }

        let tags = draft.goal.map { [tag(for: $0)] } ?? []
        store.createReminder(title: draft.title,
                             icon: .init(symbol: nil, emoji: draft.emoji),
                             date: draft.date,
                             colorName: draft.goal?.colorName ?? "sky",
                             snoozeDuration: 15 * 60,
                             scheduleBuilder: draft.scheduleBuilder,
                             reminderNotification: .notification,
                             tags: tags)
        createdReminder = draft
        advance()
    }

    private func tag(for goal: OnboardingGoal) -> TagModel {
        if let existing = store.tagModels.first(where: { $0.name.caseInsensitiveCompare(goal.tagName) == .orderedSame }) {
            return existing
        }
        return .from(store.createTag(name: goal.tagName, color: UIColor(goal.color)))
    }

    // MARK: - Notifications

    func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            notificationStatus = .granted
        case .denied:
            notificationStatus = .denied
        case .notDetermined:
            notificationStatus = .notDetermined
        @unknown default:
            notificationStatus = .notDetermined
        }
    }

    /// Asks for permission and actually reads the answer, so a denial is surfaced instead of
    /// passing silently.
    func requestNotifications() async {
        isRequestingNotifications = true
        await store.notificationManager.requestForAuthorizationAfterCheckingNotificationSettings()
        await refreshNotificationStatus()
        isRequestingNotifications = false

        guard notificationStatus == .granted else { return }
        // The first reminder was scheduled before permission existed — schedule it again.
        store.notificationManager.enableNotifications()
        advance()
    }

    func openNotificationSettings() {
        store.notificationManager.openSettings()
    }
}
