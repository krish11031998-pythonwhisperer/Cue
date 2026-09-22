//
//  CueAIViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 10/03/2026.
//

import SwiftUI
import Model
import SFSafeSymbols
import Speech
import VanorUI
import NaturalLanguage
import Combine

enum CueReminderGeneratorError: Error {
    case viewModelOutOfMemory
    case errorSavingReminder
    case errorGeneratingReminder
}

enum CueAIViewError: Error, LocalizedError, CueAlertError {
    case microphoneAccessDenied
    case audioEngineCouldNotStart
    case errorSavingRoutine
    case errorGeneratingRoutine

    var actions: [CueAlertAction] {
        switch self {
        case .microphoneAccessDenied:
            return [.cancel, .customAction("Open Settings", {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            })]
        case .audioEngineCouldNotStart, .errorSavingRoutine, .errorGeneratingRoutine:
            return [.ok]
        }
    }

    var errorDescription: String? {
        switch self {
        case .microphoneAccessDenied:
            return "Microphone Access Needed"
        case .audioEngineCouldNotStart:
            return "Couldn't Start Recording"
        case .errorSavingRoutine:
            return "Couldn't Save Reminders"
        case .errorGeneratingRoutine:
            return "Couldn't Create Reminder"
        }
    }

    var failureReason: String? {
        switch self {
        case .microphoneAccessDenied:
            return "cue:ai needs access to your microphone to turn your voice into reminders."
        case .audioEngineCouldNotStart:
            return "Something went wrong while starting the microphone."
        case .errorSavingRoutine:
            return "Your reminders couldn't be saved."
        case .errorGeneratingRoutine:
            return "cue:ai couldn't turn that into a reminder."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .microphoneAccessDenied:
            return "Turn on Microphone access for Cue in Settings, or type your reminder instead."
        case .audioEngineCouldNotStart:
            return "Make sure no other app is using the microphone, then try again."
        case .errorSavingRoutine:
            return "Please try again."
        case .errorGeneratingRoutine:
            return "Try rephrasing it with a clear title and time, e.g. \"Drink water every day at 9am\"."
        }
    }
}

@MainActor
@Observable
class CueAIViewModel: Sendable {
    
    struct AICuratedReminderModel: Identifiable, Hashable {
        let id: UUID
        var reminder: ReminderModel
        
        init(id: UUID = UUID(), reminder: ReminderModel) {
            self.id = id
            self.reminder = reminder
        }
    }
    
    
    enum GenerationState: Equatable {
        case idle
        case generate(String)
    }
    
    enum Presentation: Identifiable {
        case editReminder(ReminderModel, (ReminderModel) -> Void)
        
        var id: String {
            switch self {
            case .editReminder(let reminderModel, _):
                return reminderModel.id
            }
        }
    }
    
    let voiceTranscriber: CueVoiceTranscriber
    let store: Store
    private var transcriptionTask: Task<Void, Never>?
    
    @ObservationIgnored
    private var generateReminderTask: Task<Void, Never>?
    @ObservationIgnored
    private var recorderHasBeenSetup: Bool = false
    @ObservationIgnored
    private var sentences: Set<String> = .init()
    
    private let reminderGenerator: ReminderGenerator = .init(sessionType: .simple)
    var presentation: Presentation? = nil
    var alert: CueAIViewError? = nil
    var recorderState: CueRecorder.RecorderState = .idle
    var transribedString: AttributedString = .init()
    var volatileTranscribedText: AttributedString = .init()
    var reminders: Array<AICuratedReminderModel> = .init()
    var reminderText: String = ""
    var generationState: GenerationState = .idle
    var bubbleAnimation: Bool = false
    
    var activityIndicator: Bool = false
    var isGenerating: Bool {
        guard case .generate = generationState else {
            return false
        }
        return true
    }

    func addReminder(_ reminder: ReminderModel) -> Bool {
        return false
    }
    
    func remove(_ reminderModel: AICuratedReminderModel) {
        guard let index = self.reminders.firstIndex(where: { $0 == reminderModel }) else { return }
        reminders.remove(at: index)
    }
    
    func edit(_ reminderModel: AICuratedReminderModel) {
        self.presentation = .editReminder(reminderModel.reminder) { [weak self] edittedReminder in
            guard let index = self?.reminders.firstIndex(where: { $0 == reminderModel }) else { return }
            self?.reminders[index].reminder = edittedReminder
        }
    }
    
    var createRemindersIsEnabled: Bool {
        guard !reminders.isEmpty else { return false }
        
        // If Generating
        if case .generate = generationState {
            return false
        }

        // If Transcribing
        if case .resume = recorderState {
            return false
        }
        
        // If creating reminders
        if activityIndicator {
            return false
        }
        
        return true
    }
    
    init(store: Store) {
        self.store = store
        self.voiceTranscriber = .init()
    }
    
    @MainActor
    func generateReminderAction() {
        self.generationState = .generate(reminderText)
    }
    
    func generateReminderTask() async {
        guard case .generate(let reminderDescription) = generationState else {
            return
        }
        
        do {
            try await generateReminderWithGenerator(reminderDescription)
        } catch is CancellationError {
            return
        } catch {
            print("(ERROR) error generating reminder: ", error.localizedDescription)
            generationState = .idle
            alert = .errorGeneratingRoutine
        }
    }
    
    @concurrent
    nonisolated private func generateReminderWithGenerator(_ reminderText: String) async throws {
        guard !reminderText.isEmpty else { return }
        
        let generatedReminder = await reminderGenerator.suggestReminder(for: reminderText)
        try Task.checkCancellation()
        
        guard let generatedReminder else { return }
        // The model is only *guided* towards 1...7 (Calendar weekday component), so drop
        // anything out of range rather than persisting a weekday the rest of the app can't read.
        let weekdays = Set(generatedReminder.date.weekdays?.map(\.weekdayIntValue).filter { (1...7).contains($0) } ?? [])
        let timeSchedule: ReminderSchedule? = .init(hour: generatedReminder.date.hour, minute: generatedReminder.date.minute, intervalWeeks: generatedReminder.date.intervalWeek, weekdays: weekdays.isEmpty ? nil : weekdays, calendarDates: nil)
        
        let date = timeSchedule?.scheduleForToday ?? .now
        
        let reminder = ReminderModel(notificationType: .notification, title: generatedReminder.title, icon: .init(symbol: nil , emoji: generatedReminder.icon), date: date, snoozeDuration: 15 * 60, tasks: [], tags: [], schedule: timeSchedule, colorName: "sky", focusSession: nil)
        
        try Task.checkCancellation()
        await MainActor.run {
            self.reminders.append(.init(reminder: reminder))
            self.generationState = .idle
        }
    }
    
    
    // MARK: - Transcriber
    
    @MainActor
    func observeTranscribedText(_ stream: AsyncStream<CueTranscriber.Result>) async {
        for await text in stream {
            switch text {
            case .final(let text):
                var attributedString = text
                attributedString.foregroundColor = .proSky.baseColor
                attributedString.font = .headline
                volatileTranscribedText = ""
                self.transribedString += attributedString
                let sentence = String(attributedString.characters)
                Task {
                    await self.generateReminderFromTranscribedText(sentence)                    
                }
            case .volatile(let volatileResult):
                var attributedString = volatileResult
                attributedString.font = .body.weight(.medium)
                attributedString.foregroundColor = .proSky.foregroundSecondary
                volatileTranscribedText = attributedString
            }
        }
    }
 
    
    @concurrent
    private func generateReminderFromTranscribedText(_ transcribedString: String) async {
        do {
            print("(DEBUG) generating Reminder From Transcribed Task")
            try await self.generateReminderWithGenerator(transcribedString)
            try Task.checkCancellation()
            await MainActor.run { [weak self] in
                guard let range = self?.transribedString.range(of: transcribedString) else { return }
                self?.transribedString.removeSubrange(range.lowerBound..<range.upperBound)
            }
        } catch {
            print("(ERROR) error: ", error.localizedDescription)
        }
    }
    
    
    // MARK: - Create Reminders
    
    @MainActor
    func createReminders() async {
        do {
            activityIndicator = true
            try await withThrowingDiscardingTaskGroup(returning: Void.self) { [weak self] group in
                guard let reminders = self?.reminders else {
                    throw CueReminderGeneratorError.viewModelOutOfMemory
                }
                
                for reminderModel in reminders {
                    group.addTask { @MainActor [weak self] in
                        let reminder = reminderModel.reminder
                        let schedule: Reminder.ScheduleBuilder?
                        if let generatedSchedule = reminder.schedule {
                            schedule = .init(hour: generatedSchedule.hour,
                                             minute: generatedSchedule.minute,
                                             intervalWeek: generatedSchedule.intervalWeeks == 0 ? nil : generatedSchedule.intervalWeeks,
                                             weekdays: generatedSchedule.weekdays,
                                             dates: generatedSchedule.calendarDates)
                        } else {
                            schedule = nil
                        }
                        try Task.checkCancellation()
                        
                        // MARK:  Create Reminder Subtasks
                        
                        let reminderTasks = await self?.createReminderSubTasks(reminder.tasks) ?? []
                        
                        // MARK: Create Focus Session for Reminder
                        
                        var createdFocusSessionModel: Model.FocusSession?
                        if let focusSession = reminder.focusSession {
                            createdFocusSessionModel = self?.store.createFocusSession(name: focusSession.name,
                                                                          sessionType: focusSession.sessionType,
                                                                          timerDuration: focusSession.timerDuration,
                                                                          breakDuration: focusSession.breakDuration,
                                                                          blockedApps: focusSession.blockedApps,
                                                                          alarm: focusSession.alarm,
                                                                          sessionCount: focusSession.sessionCount)
                        }
                        
                        self?.store.createReminder(title: reminder.title,
                                                   icon: reminder.icon,
                                                   date: reminder.date,
                                                   colorName: reminder.colorName,
                                                   snoozeDuration: reminder.snoozeDuration,
                                                   scheduleBuilder: schedule,
                                                   tasks: reminderTasks,
                                                   reminderNotification: .notification,
                                                   tags: reminder.tags,
                                                   focusSession: createdFocusSessionModel)
                    }
                }
                
                print("(DEBUG) all Reminders were created!")
            }
        } catch {
            print("(ERROR) there as an error while creating the reminders: ", error.localizedDescription)
            alert = .errorSavingRoutine
        }
        activityIndicator = false
    }
    
    
    private func createReminderSubTasks(_ tasks: [ReminderTaskModel]) async -> [ReminderTaskModel] {
        return await withTaskGroup(of: ReminderTaskModel?.self) { [weak self] group in
            for task in tasks {
                group.addTask { @MainActor in
                    guard let task = self?.store.createReminderTask(title: task.title, icon: task.icon) else { return nil }
                    return .init(from: task)
                }
            }
            
            var createdTasks: [ReminderTaskModel] = []
            for await createdTask in group where createdTask != nil  {
                createdTasks.append(createdTask!)
            }
            
            return createdTasks
        }
    }
    
    // MARK: - VoiceRecorder
    
    func setupVoiceRecorder() async {
        do {
            try await voiceTranscriber.startOrResume()
        } catch {
            handleRecorderError(error)
            return
        }
    }

    @MainActor
    func setupRecorderAndStart() async {
        await setupVoiceRecorder()
        guard transcriptionTask == nil else { return }
        transcriptionTask = Task { @MainActor in
            let transcription = self.voiceTranscriber.transcriptionStream()
            await observeTranscribedText(transcription)
        }
    }
    
    private func handleRecorderError(_ error: Error) {
        print("(ERROR) error starting recorder: ", error.localizedDescription)
        if case CueRecorder.RecorderError.accessToMicrophoneDenied = error {
            alert = .microphoneAccessDenied
        } else {
            alert = .audioEngineCouldNotStart
        }
        recorderState = .idle
    }

    func pauseRecording() {
        voiceTranscriber.pause()
    }
    
    func stopRecorder() async {
        transcriptionTask?.cancel()
        transcriptionTask = nil
        await voiceTranscriber.stop()
    }
    
    // ViewModel + View Methods
    
    func handleChangeOfRecorderState() async {
        switch recorderState {
        case .idle:
            break
        case .resume:
            await self.setupRecorderAndStart()
        case .stop:
            await self.stopRecorder()
        case .pause:
            self.pauseRecording()
        }
    }
}
