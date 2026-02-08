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
        if let symbol = icon.symbol {
            return UIImage(systemName: symbol)!
        } else if let emoji = icon.emoji {
            return UIGraphicsImageRenderer(size: size).image { context in
                let font = UIFont.preferredFont(forTextStyle: .headline)
                let height = font.lineHeight
                let width = emoji.size(withAttributes:[.font: font]).width
                
                let xOff = (size.width - width) / 2
                let yOff = (size.height - height) / 2
                
                emoji.draw(in: .init(origin: .init(x: xOff, y: yOff), size: size), withAttributes: [.font: font])
            }
        } else {
            return UIImage(systemName: "photo")!
        }
    }
}
