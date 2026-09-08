//
//  FocusTimerType.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/08/2026.
//

import Foundation
import VanorUI
import SwiftUI
internal import AlarmKit
import AsyncAlgorithms
import FamilyControls
import Model
import ManagedSettings

// NOTE: `FocusTimerType` now lives in VanorUI (Resources/FocusTimerType.swift) so that
// FTLaunchControlView can branch its layout on it.

@Observable
@MainActor
class FocusSessionCoordinator: FocusSessionControl {
    
    enum AlarmAt {
        case endOfSession
        case betweenPomodoroSessions
    }
    
    static let defaultTimer: TimeInterval = 30 * 60
    static let defaultPomodoroTimer: TimeInterval = 25 * 60
    static let defaultBreakTimer: TimeInterval = 5 * 60
    
    
    // MARK: - Computed Properties from Current `Session`
    
    // MARK: Current `FocusSession`
    
    var state: FocusSessionState {
        guard let session else { return .idle }
        return session.state
    }
    
    var progress: CGFloat {
        guard let session else { return 0 }
        return session.timerProgress
    }
    
    var remainingTimeDuration: TimeInterval {
        let remainingTimeInterval = currentSessionTimeDuration() * (1 - progress)
        return remainingTimeInterval
    }
    
    
    var startTime: Date? {
        session?.startTime
    }
    
    var endTime: Date? {
        session?.endTime
    }
    
    var pausedAt: Date? {
        session?.pausedAt
    }
    
    var currentSessionIndex: Int {
        session?.currentClassicSessionIndex ?? 0
    }
    
    
    // MARK: Others
    
    private var timerDurationString: String? {
        guard let startTime, let endTime, let totalDuration = session?.totalDuration else { return nil }
        let dateFormatter: DateFormatter = .init()
        dateFormatter.dateFormat = "hh:mm"
        
        let startTimeString = dateFormatter.string(from: startTime)
        let endTimeString = dateFormatter.string(from: endTime)
        
        let durationFromStartToEnd = endTime.timeIntervalSince(startTime)
        #warning("Will Come Back to this")
//        let diffString = (durationFromStartToEnd - totalDuration).timerDurationString
        return "\(startTimeString) → \(endTimeString)"
    }
    
    var informationString: String {
        var resultString: String = ""
        if let timerDurationString = timerDurationString {
            resultString += timerDurationString
        }
        
        if numberOfTasks > 0 {
            resultString += " • \(numberOfTasks) tasks"
        }
        
        return resultString
    }
    
    
    // MARK: - Properties
    
    private(set) var session: FocusSession?
    var timerDuration: TimeInterval
    
    // Pomodoro timer related variables
    var breakDuration: TimeInterval
    var pomodoroSessionCount: Int = 2
    
    var showTasksSheet: Bool = false
    var selectedTimerType: FocusTimerType = .classic {
        didSet {
            switch selectedTimerType {
            case .classic:
                timerDuration = Self.defaultTimer
                alarmAt = .endOfSession
            case .pomodoro:
                timerDuration = Self.defaultPomodoroTimer
            }
        }
    }
    
    @ObservationIgnored
    var alarmAt: AlarmAt = .endOfSession
    @ObservationIgnored
    var shieldConfiguration: CueShieldConfigurationModel?
    @ObservationIgnored
    var shieldActivities: FamilyActivitySelection = .init()
    @ObservationIgnored
    var numberOfTasks: Int {
        get { sessionAttributes?.numberOfTasks ?? 0 }
        set { }
    }
    @ObservationIgnored
    private var liveAcitivityObservation: Task<Void, Never>?
    
    @ObservationIgnored
    var reminderModel: ReminderModel? {
        get { storeCoordinator?.reminder }
        set { storeCoordinator?.reminder = newValue }
    }
    
    var sessionAttributes: FocusSessionAttributes?
    var canShowAlarm: Bool = false
    var isAlarmOn: Bool = false
    var appShieldIsOn: Bool = false
    
    private let alarmCoordinator: FocusTimerAlarmCoordinator?
    private let liveActivityCoordindator: FocusTimerLiveActivityCoordinator?
    private let appShieldCoordinator: FocusAppShieldCoordinator?
    private let storeCoordinator: StoreCoordinator?
    
    init(alarmCoordinator: FocusTimerAlarmCoordinator?,
         liveActivityCoordinator: FocusTimerLiveActivityCoordinator?,
         appShieldCoordinator: FocusAppShieldCoordinator?,
         storeCoordinator: StoreCoordinator?) {
        self.alarmCoordinator = alarmCoordinator
        self.liveActivityCoordindator = liveActivityCoordinator
        self.appShieldCoordinator = appShieldCoordinator
        self.storeCoordinator = storeCoordinator
        self.timerDuration = FocusSessionCoordinator.defaultTimer
        self.breakDuration = FocusSessionCoordinator.defaultBreakTimer
    }
    
    func startTimer() {
        switch selectedTimerType {
        case .classic:
            session = ClassicFocusSession(timerDuration: timerDuration)
        case .pomodoro:
            session = PomodoroFocusSession(sessionCount: pomodoroSessionCount, singleSessionDuration: timerDuration, breakSessionDuration: breakDuration)
        }
        session?.startTimer()
        setupAlarmForSession()
        setupLiveActivity()
        applyAppShield()
        session?.control = self
    }
    
    func pauseTimer() {
        self.session?.pauseTimer()
        updateStateOfLiveActivity()
    }
    
    func resumeTimer() {
        self.session?.resumeTimer()
        updateStateOfLiveActivity()
    }
    
    func reset() {
        logCompletedReminderTasks()
        self.timerDuration = FocusSessionCoordinator.defaultTimer
        if case .classic = selectedTimerType {
            self.session?.resetTimer()
        }
        endLiveActivity()
        removeAppShield()
        self.session = nil
    }
    
    func cancelAndReset() {
        cancelScheduledAlarm()
        reset()
    }
    
    func presentTaskSheet() {
        switch state {
        case .idle, .reset:
            showTasksSheet = false
        case .start, .resume, .pause:
            showTasksSheet = true
        }
    }
    
    
    // MARK: - Session Helpers
    
    func currentSessionTimeDuration() -> TimeInterval {
        switch selectedTimerType {
        case .classic:
            return timerDuration
        case .pomodoro:
            guard let duration = session?.currentTimerDuration else {
                fatalError("Can't be a Classic Timer session when the seletedTimerType is Pomodoro")
            }
            return duration
        }
    }
    
    
    // MARK: - LiveActivity
    
    private func setupLiveActivity() {
        guard var sessionAttributes,
              let startTime,
              let totalDuration = session?.totalDuration else { return }
        
        sessionAttributes.sessionType = {
            switch selectedTimerType {
            case .classic:
                return .classic
            case .pomodoro:
                return .pomodoro
            }
        }()
        
        let endDate = startTime.addingTimeInterval(totalDuration)
        let activityID = UUID()
        session?.liveActivityID = activityID
        
        liveActivityCoordindator?.setupLiveActivity(for: activityID, sessionAttributes: sessionAttributes, startDate: startTime, endDate: endDate)
//        updateLiveActivityWithProgress()
    }
    
    private func updateStateOfLiveActivity() {
        guard let session, let activityID = session.liveActivityID else { return }
        let isPaused: Bool
        switch session.state {
        case .resume:
            isPaused = false
        case .pause:
            isPaused = true
        case .idle, .start, .reset:
            return
        }
        
        guard let endTime = session.endTime else { return }
        let activityState = FocusSessionLiveActivityAttributes.ContentState(restTime: 0, endDate: endTime, progress: session.timerProgress, completedTasks: 0, isPaused: isPaused)
        print("(DEBUG) state: ", state)
        liveActivityCoordindator?.updateLiveAcitivity(for: activityID, content: activityState)
    }
    
    private func endLiveActivity() {
        liveAcitivityObservation?.cancel()
        guard let activityID = session?.liveActivityID else { return }
        liveActivityCoordindator?.endLiveActivity(for: activityID)
    }
    
    
    // MARK: - Alarms
    
    func setupAlarmForOngoingSesion() {
        isAlarmOn = true
        setupAlarmForSession()
    }
    
    private func setupAlarmForSession() {
        switch alarmAt {
        case .endOfSession:
            if let startDate = session?.startTime {
                Task { @MainActor in
                    
                    var timeInterval: TimeInterval
                    
                    switch selectedTimerType {
                    case .classic:
                        timeInterval = self.timerDuration
                    case .pomodoro:
                        timeInterval = Double(pomodoroSessionCount) * self.timerDuration + Double(self.pomodoroSessionCount - 1) * self.breakDuration
                    }
                    
                    let id = await self.scheduleAlarm(title: titleForAlarm, startTime: startDate, timerDuration: timeInterval)
                    session?.alarmID = id
                }
            }
        case .betweenPomodoroSessions:
            guard let pomodoroSession = session as? PomodoroFocusSession else {
                fatalError("Attempting to add multiple alarms for a non-pomodoro session")
            }
            
            guard let startTime = session?.startTime else { return }
            
            let timerDuration = self.timerDuration
            let breakDuration = self.breakDuration
            
            Task { @MainActor in
                let alarmIds: [UUID] = await withTaskGroup(of: UUID?.self) { group in
                    for idx in 0..<pomodoroSessionCount {
                        group.addTask {
                            let timeDiff = Double(idx) * (timerDuration + breakDuration)
                            let alarmStartTime = startTime.addingTimeInterval(timeDiff)
                            
                            return await self.scheduleAlarm(title: self.titleForAlarm, startTime: alarmStartTime, timerDuration: self.timerDuration)
                        }
                    }
                    
                    var alarmUUIDs: [UUID] = []
                    
                    for await uuid in group {
                        if let uuid {
                            alarmUUIDs.append(uuid)
                        }
                    }
                    
                    return alarmUUIDs
                }
                
                pomodoroSession.allAlarmIDs = alarmIds
            }
        }
    }
    
    private var titleForAlarm: String {
        let alarmTitle: String
        switch selectedTimerType {
        case .classic:
            alarmTitle = "Classic Alarm"
        case .pomodoro:
            alarmTitle = "Pomodoro Alarm"
        }
        
        return alarmTitle
    }
    
    func checkIfCanSetAlarm() async {
        switch await alarmCoordinator?.authorizationStatus() {
        case .notDetermined, .authorized:
            self.canShowAlarm = true
        case .denied:
            self.canShowAlarm = false
        case .none:
            self.canShowAlarm = false
        @unknown default:
            self.canShowAlarm = false
        }
    }
    
    func toggleAlarm() {
        if isAlarmOn == false {
            self.turnOnAlarm()
        } else {
            self.isAlarmOn = false
        }
    }
    
    func turnOnAlarm() {
        Task { @MainActor in
            let isAuthorized = await self.alarmCoordinator?.requestAuthorization()
            guard let isAuthorized, isAuthorized else { return }
            self.isAlarmOn = true
        }
    }
    
    func updateAlarmAt(_ alarmAt: AlarmAt) {
        guard case .pomodoro = selectedTimerType else {
            fatalError("Can only be set when the session is Pomodoro")
        }
        
        self.alarmAt = alarmAt
        turnOnAlarm()
    }
    
    @discardableResult
    func scheduleAlarm(title: String, startTime: Date, timerDuration: TimeInterval) async -> UUID? {
        guard isAlarmOn else { return nil }
        let data = await alarmCoordinator?.scheduleAlarmForTimer(startDate: startTime, timeInterval: timerDuration, title: title, color: Color.proSky.baseColor)
        guard let (uuid, _) = data else { return nil }
        return uuid
    }
    
    func cancelScheduledAlarm() {
        
        func cancelSingleAlarm(session: FocusSession?) {
            guard let alarmID = session?.alarmID else { return }
            alarmCoordinator?.cancelAlarm(alarmID)
            session?.alarmID = nil
        }
        
        func cancelAllAlarms(session: FocusSession?) {
            guard let pomodoroSession = session as? PomodoroFocusSession else { return }
            pomodoroSession.allAlarmIDs.forEach {
                alarmCoordinator?.cancelAlarm($0)
            }
            pomodoroSession.allAlarmIDs = []
        }
        
        switch selectedTimerType {
        case .classic:
            cancelSingleAlarm(session: session)
        case .pomodoro:
            switch alarmAt {
            case .endOfSession:
                cancelSingleAlarm(session: session)
            case .betweenPomodoroSessions:
                cancelAllAlarms(session: session)
            }
        }
        
        isAlarmOn = false
    }
    
    
    // MARK: - AppShield
    
    func applyAppShieldForOngoingSession() {
        appShieldIsOn = true
        applyAppShield()
    }
    
    private func applyAppShield() {
        guard appShieldIsOn, let shieldConfiguration else { return }
        appShieldCoordinator?.saveShieldConfiguration(shieldConfiguration)
        appShieldCoordinator?.applyRestrictions(shieldActivities)
    }
    
    func removeAppShield() {
        appShieldCoordinator?.removeRestrictions()
        shieldActivities = .init()
        appShieldIsOn = false
    }
    
    
    // MARK: - ReminderModel
    
    var completedReminderTasks: Set<ReminderTaskModel> {
        get { .init(storeCoordinator?.completedTasks ?? []) }
        set { storeCoordinator?.completedTasks = .init(newValue) }
    }
    var reminderTasks: [ReminderTaskModel] {
        storeCoordinator?.reminderTasks ?? []
    }
    func logReminderModel(_ reminderModel: ReminderTaskModel) {
        Task { @MainActor [weak self] in
            await self?.storeCoordinator?.saveTask(reminderModel)
        }
    }
    private func logCompletedReminderTasks() {
        for task in completedReminderTasks {
            logReminderModel(task)
        }
    }
    
    
    // MARK: - FocusSessionControl
    
    func onCompletion() {
        self.reset()
    }
    
    
    // MARK: - FocusSessionModel
    
    func startWithFocusSessionModel(_ focusSessionModel: FocusSessionModel) {
        switch focusSessionModel.sessionType {
        case .classic:
            selectedTimerType = .classic
        case .pomodoro:
            selectedTimerType = .pomodoro
        @unknown default:
            selectedTimerType = .classic
        }

        timerDuration = focusSessionModel.timerDuration
        breakDuration = focusSessionModel.breakDuration
        
        pomodoroSessionCount = focusSessionModel.sessionCount ?? 2
        switch focusSessionModel.alarm {
        case .off:
            isAlarmOn = false
        case .endOfSession:
            alarmAt = .endOfSession
            isAlarmOn = true
        case .betweenSessions:
            alarmAt = .betweenPomodoroSessions
            isAlarmOn = true
        @unknown default:
            isAlarmOn = false
        }
        
        if let blockedApps = focusSessionModel.blockedApps {
            shieldActivities = blockedApps
            appShieldIsOn = true
        } else {
            shieldActivities = .init()
            appShieldIsOn = false
        }
        
        setupLiveActivityAttributes(for: focusSessionModel)
        setupAppShieldConfiguration(for: focusSessionModel)
        if let reminderModel = focusSessionModel.reminder {
            self.reminderModel = reminderModel
        }
        startTimer()
    }
    
    private func setupLiveActivityAttributes(for focusSessionModel: FocusSessionModel) {
        if let reminderModel = focusSessionModel.reminder {
            sessionAttributes = .init(name: reminderModel.title, color: .init(color: reminderModel.color), icon: .init(reminderModel.icon) ?? Icon.symbol(.timer), sessionType: nil, numberOfTasks: reminderModel.tasks.count)
        } else {
            sessionAttributes = .init(name: focusSessionModel.name, color: Color.proSky, icon: .symbol(.timer), sessionType: nil, numberOfTasks: 0)
        }
    }
    
    private func setupAppShieldConfiguration(for focusSessionModel: FocusSessionModel) {
        let focusSession: CueShieldConfigurationModel.FocusSession
        let theme: LCHColor
        let title: String
        let subtitle: String
        
        if let reminderModel = focusSessionModel.reminder {
            let reminderImage: UIImage?
            if let symbol = reminderModel.icon.symbol {
                reminderImage = .init(systemName: symbol)
            } else if let emoji = reminderModel.icon.emoji{
                reminderImage = UIImage.imageFromEmoji(.init(emoji), fontSize: nil, size: .init(squared: 48))
            } else {
                reminderImage = nil
            }
            
            theme = .init(color: reminderModel.color)
            focusSession = .init(icon: reminderImage ?? .init(systemSymbol: .questionmark),
                                 color: theme.backgroundTertiary)
            title = "Stay Focused on \(reminderModel.title)"
        } else {
            theme = Color.proSky
            let symbolColor = UIColor(theme.foregroundPrimary.resolved(for: .dark))
            let image = UIImage(systemSymbol: .timer).withTintColor(symbolColor, renderingMode: .alwaysTemplate).resized(size: .init(squared: 48))
            focusSession = .init(icon: image,
                                 color: theme.backgroundTertiary)
            title = "Stay Focused"
        }
        
        subtitle = "\nYou are currently in a focus session and have blocked \(CueShieldConfigurationModel.placeholder)"
        let titleColor = theme.foregroundSecondary.resolved(for: .dark)
        let subtitleColor = theme.foregroundTertiary.resolved(for: .dark)
        let primaryButtonForeground = Color.white
        let primaryButtonBackground = theme.baseColor
        
        let configuration = CueShieldConfigurationModel(focusSession: focusSession,
                                                        title: .init(title: title, color: titleColor),
                                                        subtitle: .init(title: subtitle, color: subtitleColor),
                                                        primaryButton: .init(title: "Remain Focused",
                                                                             foreground: primaryButtonForeground,
                                                                             background: primaryButtonBackground,
                                                                             response: .close),
                                                        secondaryButton: nil)
        shieldConfiguration = configuration
    }
}


extension FocusSessionCoordinator {
    static let previawableSessionCoordinator = FocusSessionCoordinator(alarmCoordinator: nil, liveActivityCoordinator: nil, appShieldCoordinator: nil, storeCoordinator: nil)
}
