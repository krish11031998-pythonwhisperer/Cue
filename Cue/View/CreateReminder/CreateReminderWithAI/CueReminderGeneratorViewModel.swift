//
//  CueReminderGeneratorViewModel.swift
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
class CueReminderGeneratorViewModel: Sendable {
    
    enum GenerationState: Equatable {
        case idle
        case generate(String)
    }
    
//    private let transcriber: CueTranscriber
//    private let recorder: CueRecorder
    private let voiceTranscriber: CueVoiceTranscriber
    private let store: Store
    private var transcriptionTask: Task<Void, Never>?
    
    @ObservationIgnored
    private var generateReminderTask: Task<Void, Never>?
    @ObservationIgnored
    private var recorderHasBeenSetup: Bool = false
    @ObservationIgnored
    private var sentences: Set<String> = .init()
    
    private let reminderGenerator: ReminderGenerator = .init()
    var recorderState: CueRecorder.RecorderState = .idle
    var transribedString: AttributedString = .init()
    var volatileTranscribedText: AttributedString = .init()
    var reminders: Set<ReminderModel> = .init()
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
    
//    var waveformsBuilder: AsyncStream<[CGFloat]>? {
//        recorder.waveformBarsBuilderFromAVAudioPCMBuffer
//    }
    
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
//        let transcriber = CueTranscriber()
//        self.transcriber = transcriber
//        self.recorder = .init()
        self.voiceTranscriber = .init()
//        self.observeDownloadFromTranscriber()
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
    
    private func generateReminderWithGenerator(_ reminderText: String) async throws {
        guard !reminderText.isEmpty else { return }
        
        let generatedReminder = await reminderGenerator.suggestReminder(for: reminderText)
        try Task.checkCancellation()
        
        guard let generatedReminder else { return }
        let weekdays = generatedReminder.date.weekdays?.map(\.weekdayIntValue) ?? []
        let timeSchedule: ReminderSchedule? = .init(hour: generatedReminder.date.hour, minute: generatedReminder.date.minute, intervalWeeks: nil, weekdays: nil, calendarDates: nil)
        
        let date = timeSchedule?.scheduleForToday ?? .now
        
        let reminder = ReminderModel(notificationType: .notification, title: generatedReminder.title, icon: .init(symbol: nil , emoji: generatedReminder.icon), date: date, snoozeDuration: 15 * 60, tasks: [], tags: [], schedule: timeSchedule)
        
        try Task.checkCancellation()
        await MainActor.run {
            self.reminders.insert(reminder)
            self.generationState = .idle
        }
    }
    
    
    // MARK: - Transcriber
    
    @MainActor
    func observeTranscribedText() async {
        for await text in voiceTranscriber.transcriptionStream() {
            self.generateReminderTask?.cancel()
            self.generateReminderTask = nil
            switch text {
            case .final(let text):
                var attributedString = text
                attributedString.foregroundColor = .proSky.baseColor
                attributedString.font = .headline
                volatileTranscribedText = ""
                self.transribedString += attributedString
                let sentence = String(attributedString.characters)
                print("(DEBUG) Recently uttered sentence: ", sentence)
                await self.generateReminderFromTranscribedText(sentence)
            case .volatile(let volatileResult):
                var attributedString = volatileResult
                attributedString.font = .body.weight(.medium)
                attributedString.foregroundColor = .proSky.foregroundSecondary
                print("(DEBUG) volatileTranscribeText: ", String(attributedString.characters))
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
                
                for reminder in reminders {
                    group.addTask { @MainActor [weak self] in
                        let schedule: Reminder.ScheduleBuilder?
                        if let generatedSchedule = reminder.schedule {
                            schedule = .init(hour: generatedSchedule.hour,
                                             minute: generatedSchedule.minute,
                                             intervalWeek: generatedSchedule.intervalWeeks,
                                             weekdays: generatedSchedule.weekdays,
                                             dates: generatedSchedule.calendarDates)
                        } else {
                            schedule = nil
                        }
                        try Task.checkCancellation()
                        self?.store.createReminder(title: reminder.title, icon: reminder.icon, date: reminder.date, snoozeDuration: reminder.snoozeDuration, scheduleBuilder: schedule, tasks: reminder.tasks, reminderNotification: .notification, tags: reminder.tags)
                    }
                }
                
                print("(DEBUG) all Reminders were created!")
            }
        } catch {
            print("(ERROR) there as an error while creating the reminders: ", error.localizedDescription)
        }
        activityIndicator = false
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
            await observeTranscribedText()
        }
    }
    
    func pauseRecording() {
        voiceTranscriber.pause()
    }
    
    func stopRecorder() async {
        voiceTranscriber.stop()
        transcriptionTask?.cancel()
    }
    
    
    // MARK: - Recorder -> Trasncriber
    
    
}
