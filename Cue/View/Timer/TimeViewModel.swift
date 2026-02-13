//
//  TimeViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 13/02/2026.
//

import SwiftUI
import Model
import VanorUI

@Observable
class TimerViewModel {
    
    @ObservationIgnored
    let reminderModel: ReminderModel?
    var frameOfCountdown: CGRect = .zero
    var presentSheet: Bool

    init(reminderModel: ReminderModel?) {
        self.reminderModel = reminderModel
        self.presentSheet = !(reminderModel?.tasks.isEmpty ?? true)
    }
    
    func updatePresentSheet(_ state: FocusCountdownView.TimerState) {
        guard let reminderModel,
              !reminderModel.tasks.isEmpty else { return }
        switch state {
        case .paused:
            if !presentSheet {
                self.presentSheet = true
            }
        case .completed:
            self.presentSheet = false
        case .resume:
            self.presentSheet = false
        case .idle:
            break
        }
    }
    
    var tasks: [ReminderTaskModel] {
        reminderModel?.tasks ?? []
    }
    
}
