//
//  CueIcon+Image.swift
//  Model
//
//  Created by Krishna Venkatramani on 14/09/2026.
//

import UIKit

extension CueIcon {
    
    /// Rasterises the icon for the surfaces that cannot take a SwiftUI view - AlarmKit's
    /// alarm metadata and the widget extension both hand back a `UIImage`.
    public func image(size: CGSize) -> UIImage {
        if let symbol {
            return UIImage(systemName: symbol)!
        } else if let emoji {
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
