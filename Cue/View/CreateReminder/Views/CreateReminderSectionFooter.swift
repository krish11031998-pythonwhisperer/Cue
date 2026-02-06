//
//  CreateReminderSectionFooter.swift
//  Cue
//
//  Created by Krishna Venkatramani on 20/01/2026.
//

import SwiftUI
import SFSafeSymbols
import ColorTokensKit
import VanorUI

struct CreateReminderSectionFooterView: View {
    
    let action: (String) -> Void
    @State private var taskName: String = ""
    
    init( action: @escaping (String) -> Void) {
        self.action = action
    }
    
    var body: some View {
        TextField("", text: $taskName, prompt: Text("Add"))
            .padding(.init(top: 12, leading: 16, bottom: 12, trailing: 16))
            .onSubmit {
                action(taskName)
                taskName = ""
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondarySystemBackground, in: .roundedRect(cornerRadius: 12))
    }
    
}
