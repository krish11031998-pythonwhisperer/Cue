//
//  CueAlarmAttributes.swift
//  Cue
//
//  Created by Krishna Venkatramani on 08/02/2026.
//

import AlarmKit
import UIKit

public struct CueAlarmAttributes: AlarmMetadata {
    public let icon: CueIcon
    public let title: String
    
    public func image(size: CGSize) -> UIImage {
        icon.image(size: size)
    }
}
