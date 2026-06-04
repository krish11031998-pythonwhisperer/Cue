//
//  NewCreateReminderView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 20/05/2026.
//

import VanorUI
import SwiftUI
import Model

struct NewCreateReminderView: View {
    
    enum Mode: Equatable {
        case create
        case edit(ReminderModel)
    }
    
    
    @State private var viewModel: NewCreateReminderViewModel
    @FocusState var textFieldIsFocused: Bool
    private var dismissActionFromParent: Callback?
    
    init(mode: Mode, store: Store, dismissActionFromParent: Callback? = nil) {
        self.viewModel = .init(store: store)
        self.dismissActionFromParent = dismissActionFromParent
    }
    
    var options: [ReminderOptionView.Config] {
        [
            .init(title: "Time", buttonTitle: viewModel.timeString, buttonAction: {
                // Present Time Sheet
            })
        ]
    }
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ReminderTitleView(viewModel: $viewModel, textFieldIsFocused: $textFieldIsFocused) {
                    // Dismiss
                }
                .padding(.bottom, 24)
                
                Section {
                    ForEach(options) { option in
                        ReminderOptionView(config: option)
                    }
                }
            }
            .padding(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
        }
    }
    
    
    // MARK: - ReminderTitle View
    
    struct ReminderTitleView: View {
        
        @Binding var viewModel: NewCreateReminderViewModel
        var textFieldIsFocused: FocusState<Bool>.Binding
        let autoDismiss: () -> Void
        
        var body: some View {
            HStack(alignment: .center, spacing: 8) {
                TextField("What is in your plans?",
                          text: $viewModel.reminderTitle,
                          axis: .vertical)
                .font(.headline)
                .fontWeight(.medium)
                .submitLabel(.go)
                .focused(textFieldIsFocused)
                .autoDismissOnReturn(text: $viewModel.reminderTitle, dismissKeyboard: autoDismiss)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                NewCreateReminderImageButton(color: viewModel.color, icon: viewModel.icon) {
                    // Do Something
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(width: 48, alignment: .center)
                
            }
        }
    }
    
    
    // MARK: - Reminder Options
    
    struct ReminderOptionView: View {
        
        struct Config: Identifiable {
            let title: String
            let buttonTitle: String
            let buttonAction: () -> Void
            
            var id: String {
                "\(title)_\(buttonTitle)"
            }
        }
        
        static let verticalPadding: CGFloat = 6
        static let horizontalPadding: CGFloat = 4
        
        let config: Config
        
        var body: some View {
            HStack(alignment: .center, spacing: 8) {
                Text(config.title)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: config.buttonAction) {
                    Text(config.buttonTitle)
                        .font(.body)
                        .padding(.init(top: Self.verticalPadding, leading: Self.horizontalPadding, bottom: Self.verticalPadding, trailing: Self.horizontalPadding))
                }
                .buttonStyle(.glass)
            }
        }
    }
}


#Preview {
    NewCreateReminderView(mode: .create, store: .init(), dismissActionFromParent: nil)
}
