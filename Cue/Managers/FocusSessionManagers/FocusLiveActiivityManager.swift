//
//  FocusLiveActiivityManager.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/08/2026.
//

import VanorUI
import ActivityKit
import Foundation

class FocusLiveActivityManager: FocusTimerLiveActivityCoordinator {
    
    typealias FocusActivity = Activity<FocusSessionLiveActivityAttributes>
    
    private var liveActivities: [UUID: FocusActivity] = [:]
    
    func setupLiveActivity(for activityID: UUID, sessionAttributes: FocusSessionAttributes, startDate: Date, endDate: Date) {
        
        let icon: FocusSessionLiveActivityAttributes.Icon
        
        switch sessionAttributes.icon {
        case .symbol(let sFSymbol):
            icon = .init(symbol: sFSymbol.rawValue, emoji: nil)
        case .emoji(let emoji):
            icon = .init(symbol: nil, emoji: emoji.char)
        }
        
        let colorHex = sessionAttributes.color.baseColor.getHexString()
        
        let state = FocusSessionLiveActivityAttributes.ContentState(restTime: 0, endDate: endDate, progress: 0, completedTasks: 0, isPaused: false)
        
        guard let sessionType = sessionAttributes.sessionType else { fatalError("sessionType cannot be nil") }
        
        let attributes = FocusSessionLiveActivityAttributes(startDate: startDate, icon: icon, sessionName: sessionAttributes.name, colorHex: colorHex, sessionType: sessionType, numnberOfTasks: sessionAttributes.numberOfTasks, state: state)
        
        let content = ActivityContent(state: state, staleDate: nil)
        
        do {
            let activity = try Activity.request(attributes: attributes, content: content)
            liveActivities[activityID] = activity
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func endLiveActivity(for activityID: UUID) {
        let activity = liveActivities[activityID]
        Task { @MainActor in
            await activity?.end(nil, dismissalPolicy: .immediate)
            liveActivities.removeValue(forKey: activityID)
        }
    }
    
    func updateLiveAcitivity(for activityID: UUID, content: FocusSessionLiveActivityAttributes.ContentState) {
        let activity = liveActivities[activityID]
        Task { @MainActor in
            let newContentState = ActivityContent(state: content, staleDate: nil)
            print("(DEBUG) newContentState: ", newContentState)
            await activity?.update(newContentState)
        }
    }
}

