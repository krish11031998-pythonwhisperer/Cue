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
        } catch {
            print("(ERROR) Propagate error to view")
        }
    }
    
    @concurrent
    nonisolated private func generateReminderWithGenerator(_ reminderText: String) async throws {
        guard !reminderText.isEmpty else { return }
        
        let generatedReminder = await reminderGenerator.suggestReminder(for: reminderText)
        try Task.checkCancellation()
        
        guard let generatedReminder else { return }
        let weekdays = generatedReminder.date.weekdays?.map(\.weekdayIntValue) ?? []
        let timeSchedule: ReminderSchedule? = .init(hour: generatedReminder.date.hour, minute: generatedReminder.date.minute, intervalWeeks: generatedReminder.date.internvalWeek, weekdays: Set(weekdays), calendarDates: nil)
        
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
                        #warning("Need to fix this before saving")
                        
                        // MARK: - Create Reminder Subtasks
                        
                        let reminderTasks = await self?.createReminderSubTasks(reminder.tasks) ?? []
                        
                        self?.store.createReminder(title: reminder.title, icon: reminder.icon, date: reminder.date, colorName: reminder.colorName, snoozeDuration: reminder.snoozeDuration, scheduleBuilder: schedule, tasks: reminderTasks, reminderNotification: .notification, tags: reminder.tags)
                    }
                }
                
                print("(DEBUG) all Reminders were created!")
            }
        } catch {
            print("(ERROR) there as an error while creating the reminders: ", error.localizedDescription)
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
        await voiceTranscriber.setup()
    }
    
    @MainActor
    func setupRecorderAndStart() async {
        await voiceTranscriber.startOrResume()
        guard transcriptionTask == nil else { return }
        transcriptionTask = Task { @MainActor in
            let transcription = self.voiceTranscriber.transcriptionStream()
            await observeTranscribedText(transcription)
        }
    }
    
    func pauseRecording() {
        voiceTranscriber.pause()
    }
    
    func stopRecorder() async {
        transcriptionTask?.cancel()
        transcriptionTask = nil
        await voiceTranscriber.stop()
    }
    
    
    // MARK: - Recorder -> Trasncriber
    
    
}
