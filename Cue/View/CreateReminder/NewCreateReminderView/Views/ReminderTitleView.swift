//
//  ReminderTitleView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 26/07/2026.
//

import VanorUI
import SwiftUI

// MARK: - ReminderTitle View

struct ReminderTitleView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.theme) var theme
    @Binding var viewModel: NewCreateReminderViewModel
    var textFieldIsFocused: FocusState<Bool>.Binding
    let emojiAndColorPicker: () -> Void
    let autoDismiss: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            TextField("What is in your plans?".lowercased(),
                      text: $viewModel.reminderTitle,
                      axis: .vertical)
            .font(.bitcountRegular(style: .headline))
            .submitLabel(.go)
            .focused(textFieldIsFocused)
            .autoDismissOnReturn(text: $viewModel.reminderTitle, dismissKeyboard: autoDismiss)
            .padding(.leading, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            NewCreateReminderImageButton(color: viewModel.color, icon: viewModel.icon) {
                // Do Something
                emojiAndColorPicker()
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(width: 42, alignment: .center)
        }
        .padding(.init(top: 12, leading: 12, bottom: 12, trailing: 12))
        .background(alignment: .center, content: {
            LinearGradient(colors: [.cueItBackground.opacity(0.25), viewModel.color.baseColor], startPoint: .leading, endPoint: .trailing)
        })
        .clipShape(.capsule)
    }
}
