//
//  Image+Emoji.swift
//  Cue
//
//  Created by Krishna Venkatramani on 08/08/2026.
//

import SwiftUI
import UIKit

extension Image {
    @MainActor
    static func fromEmoji(_ emoji: String, fontSize: CGFloat? = nil, size: CGSize) -> Image? {
        let baseFontSize = fontSize ?? min(size.width, size.height)

        let renderer = ImageRenderer(content:
            Text(emoji)
                .font(.system(size: baseFontSize))
                .lineLimit(1)
                .minimumScaleFactor(0.01)
                .frame(width: size.width, height: size.height)
        )
        renderer.scale = UITraitCollection.current.displayScale

        guard let cgImage = renderer.cgImage else { return nil }
        return Image(decorative: cgImage, scale: renderer.scale)
    }
}
