//
//  ActionSegmentControlListRow.swift
//  Cue
//
//  Created by Krishna Venkatramani on 12/07/2026.
//

import SwiftUI
import VanorUI


enum ActionSegmentControlOptionContentProvider {
    case title(String)
    case symbol(SFSymbol)
    case label(String, SFSymbol)
}

protocol ActionSegmentControlOption: Identifiable, Hashable {
    var content: ActionSegmentControlOptionContentProvider { get }
}

struct ActionSegmentControlListRow<Option: ActionSegmentControlOption>: View  {
   
    struct ActionSegmentControlConfig: Identifiable {
        
        typealias Content = [Option]
        
        var content: [Option]
        @Binding var selectedOption: Option
        
        var id: Int {
            var hasher: Hasher = .init()
            content.forEach { content in
                hasher.combine(content.id)
            }
            return hasher.finalize()
        }
    }
    
    let config: ActionSegmentControlConfig
    
    var body: some View {
        Picker("", selection: config.$selectedOption) {
            ForEach(config.content) { content in
                Group {
                    switch content.content {
                    case .label(let title, let symbol):
                        HStack(alignment: .center, spacing: 4) {
                            Image(systemSymbol: symbol)
                            Text(title)
                        }
                    case .symbol(let symbol):
                        Image(systemSymbol: symbol)
                    case .title(let title):
                        Text(title)
                    }
                }
                .font(.subheadline)
            }
        }
    }
}
