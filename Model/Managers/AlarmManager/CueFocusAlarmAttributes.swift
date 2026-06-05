//
//  CueFocusAlarmAttributes.swift
//  Cue
//
//  Created by Krishna Venkatramani on 05/06/2026.
//

import AlarmKit

public struct CueFocusAlarmAttributes: AlarmMetadata {
    public let title: String
    public init(title: String) {
        self.title = title
    }
}
