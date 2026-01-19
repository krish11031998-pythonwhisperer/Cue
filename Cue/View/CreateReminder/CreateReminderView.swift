//
//  CreateReminderView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 18/01/2026.
//

import SwiftUI
import VanorUI
internal import SFSafeSymbols
import ColorTokensKit

struct CreateReminderView: View {
    
    @State private var viewModel: CreateReminderViewModel = .init()
    @Namespace private var animation
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 0) {
                TextField("Create Reminder", text: $viewModel.reminderTitle, axis: .vertical)
                    .font(.title)
                    .fontWeight(.medium)
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
                    HStack(alignment: .center, spacing: 8) {
                        Text("Add Tasks")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Button {
                            print("(DEBUG) AI tapped")
                        } label: {
                            Image(systemSymbol: .sparkles)
                                .font(.subheadline)
                        }
                        .tint(Color.proSky.baseColor)
                        .buttonStyle(.glassProminent)
                    }
                    .padding(.top, 32)
                } footer: {
                    Button {
                        viewModel.addTask()
                    } label: {
                        Label {
                            Text("Add")
                        } icon: {
                            Image(systemSymbol: .plus)
                        }
                        .font(.footnote)
                        .fontWeight(.semibold)
//                        .padding(.init(top: 6, leading: 10, bottom: 6, trailing: 10))
                    }
                    .buttonStyle(.glass)

//                    .glassEffect(.regular, in: .capsule)
                    .padding(.top, 12)
                }

            }
            .padding(.horizontal, 20)
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
    CreateReminderView()
}
