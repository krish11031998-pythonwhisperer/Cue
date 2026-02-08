//
//  AlarmButton+Cue.swift
//  Cue
//
//  Created by Krishna Venkatramani on 08/02/2026.
//

import AlarmKit
import SwiftUI

extension AlarmButton {
    
    static var snoozeButton: Self {
        .init(text: .init(stringLiteral: "Snooze"), textColor: .white, systemImageName: "zzz")
    }
    
    static var stopButton: Self {
        .init(text: .init(stringLiteral: "Stop"), textColor: .white, systemImageName: "stop.fill")
    }
    
    static var pauseButton: Self {
        .init(text: .init(stringLiteral: "Pause"), textColor: .white, systemImageName: "pause.fill")
    }
    
    static var resumeButton: Self {
        .init(text: .init(stringLiteral: "Stop"), textColor: .white, systemImageName: "play.fill")
    }
    
}
