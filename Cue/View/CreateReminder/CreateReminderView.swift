//
//  CreateReminderView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 18/01/2026.
//

import SwiftUI
import VanorUI
import Model

struct CreateReminderView: View {
    
    @State private var viewModel: CreateReminderViewModel
    @Namespace private var animation
    @Environment(\.dismiss) var dismiss
    
    init(store: Store) {
        self._viewModel = .init(initialValue: .init(store: store))
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    CreateReminderTextView(selectedSymbol: $viewModel.icon,
                                           reminderTitle: $viewModel.reminderTitle)
                        .padding(.top, 16)
                    
                    OverFlowingHorizontalLayout(horizontalSpacing: 8, verticalSpacing: 10) {
                        ForEach(CreateReminderViewModel.Presentation.allCases) { presentation in
                            ReminderButton(presentation: presentation,
                                           buttonTitle: viewModel.buttonTitleForElement(presentation),
                                           animation: animation) { presentation in
                                self.viewModel.presentation = presentation
                            }
                        }
                    }
                    .padding(.top, 12)
                    
                    Section {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(viewModel.taskViewModels) { taskViewModel in
                                ReminderTaskView(model: taskViewModel)
                                    .transition(.scale(scale: 1, anchor: .center))
                            }
                        }
                        .padding(.top, 16)
                    } header: {
                        CreateReminderSectionHeaderView {
                            print("(DEBUG) tapped on section HeaderView")
                        }
                        .padding(.top, 32)
                    } footer: {
                        CreateReminderSectionFooterView {
                            viewModel.addTask()
                        }
                        .padding(.top, 12)
                    }
                }
                .padding(.horizontal, 20)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .confirm) {
                        viewModel.createReminder()
                        self.dismiss()
                    }
                    .tint(Color.proSky.baseColor)
                }
            }
        }
        .sheet(item: $viewModel.presentation) { sheet in
            Group {
                switch sheet {
                case .alarmAt:
                    DatePicker(selection: $viewModel.timeDate, displayedComponents: [.hourAndMinute]) {
                        Color.clear
                            .frame(width: 0, height: 0)
                    }
                    .datePickerStyle(.wheel)
                    .padding(.horizontal, 20)
                case .duration:
                    SnoozeTimerSheet(timeDuration: $viewModel.snoozeDuration)
                case .date:
                    DatePicker("Select Date",
                               selection: $viewModel.date,
                               displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                }
            }
            .fittedPresentationDetent()
            .navigationTransition(.zoom(sourceID: sheet, in: animation))
        }
    }
    
    
    // MARK: - ReminderButton
    
    struct ReminderButton: View {
        
        let presentation: CreateReminderViewModel.Presentation
        let buttonTitle: String
        var animation: Namespace.ID
        let action: (CreateReminderViewModel.Presentation) -> Void
        
        var body: some View {
            Button {
                action(presentation)
            } label: {
                Label {
                    Text(buttonTitle)
                } icon: {
                    Image(systemSymbol: symbol)
                }
                .font(.subheadline)
                .fontWeight(.semibold)
            }
            .buttonStyle(.glass)
            .matchedTransitionSource(id: presentation,
                                     in: animation)
        }
        
        
        // MARK:  Symbol
        
        var symbol: SFSymbol {
            switch presentation {
            case .alarmAt:
                return .alarm
            case .duration:
                return .zzz
            case .date:
                return .calendar
            }
        }
        
    }
}

#Preview {
    CreateReminderView(store: .init())
}
