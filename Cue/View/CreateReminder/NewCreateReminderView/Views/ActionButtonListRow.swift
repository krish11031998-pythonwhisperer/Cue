//
//  ActionButtonListRow.swift
//  Kyu
//
//  Created by Krishna Venkatramani on 12/07/2026.
//

import Foundation
import SwiftUI
import VanorUI

struct ActionButtonListRow: View {
    
    struct Config: Identifiable {
        
        enum Content {
            case string(String)
            case symbol(SFSymbol)
            case label(SFSymbol, String)
        }
        
        var content: Content
        let action: Callback
        
        init(title: String, action: @escaping Callback) {
            self.content = .string(title)
            self.action = action
        }
        
        init(symbol: SFSymbol, action: @escaping Callback) {
            self.content = .symbol(symbol)
            self.action = action
        }
        
        init(symbol: SFSymbol, label: String, action: @escaping Callback) {
            self.content = .label(symbol, label)
            self.action = action
        }
        
        var id: String {
            switch content {
            case .string(let string):
                return string
            case .symbol(let sFSymbol):
                return sFSymbol.rawValue
            case .label(let sFSymbol, let string):
                return "\(sFSymbol.rawValue)-\(string)"
            }
        }
        
        static func edit(action: @escaping Callback) -> Self {
            .init(symbol: .pencil, action: action)
        }
    }
    
    let config: Config
    private let verticalPadding: CGFloat = 4
    private let horizontalPadding: CGFloat = 4
    
    var body: some View {
        Button(action: config.action) {
            ZStack(alignment: .center) {
                switch config.content {
                case .string(let string):
                    Text(string)
                        .font(.subheadline.weight(.medium))
                case .symbol(let sFSymbol):
                    Image(systemSymbol: sFSymbol)
                        .font(.subheadline.weight(.medium))
                case .label(let symbol, let title):
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Image(systemSymbol: symbol)
                            .font(.subheadline.weight(.medium))
                        Text(title)
                            .font(.subheadline.weight(.medium))
                    }
                }
            }
            .padding(.init(top: verticalPadding, leading: horizontalPadding, bottom: verticalPadding, trailing: horizontalPadding))
        }
        .buttonStyle(.glass)
    }
}
