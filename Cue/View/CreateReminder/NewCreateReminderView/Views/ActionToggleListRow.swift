//
//  ActionToggleListRow.swift
//  Cue
//
//  Created by Krishna Venkatramani on 12/07/2026.
//

import SwiftUI
import VanorUI


struct ActionToggleListRow: View {
    
    struct Config: Identifiable {
        var content: Bool
        let action: (Bool) -> Void
        
        var id: String { content ? "ActionToggleListView_true" : "ActionToggleListView_false" }
    }
    
    @State private var isOn: Bool
    let config: Config
    
    init(config: Config) {
        self.config = config
        self._isOn = .init(initialValue: config.content)
    }
    
    var body: some View {
        Toggle("", isOn: $isOn)
            .padding(.vertical, 4)
            .onChange(of: isOn, initial: false) { _, newValue in
                config.action(newValue)
            }
    }
}
