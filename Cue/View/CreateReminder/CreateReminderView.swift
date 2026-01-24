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
    @State private var imageFrame: CGRect = .zero
    
    init(store: Store) {
        self._viewModel = .init(initialValue: .init(store: store))
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    
                    Button {
                        viewModel.presentation = .symbolAndColor
                    } label: {
                        Image(systemSymbol: viewModel.icon)
                            .resizable()
                            .scaledToFit()
                            .padding(.all, 12)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .glassEffect(.regular.tint(viewModel.color.baseColor), in: .circle)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 84, height: 84, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 32)
                    .onGeometryChange(for: CGRect.self,
                                      of: { $0.frame(in: .global) },
                                      action: { imageFrame = $0 })
                    
                    TextField("Create Reminder",
                              text: $viewModel.reminderTitle,
                              axis: .vertical)
                    .font(.title)
                    .fontWeight(.medium)
                    
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
                    .fittedPresentationDetent()
                case .duration:
                    SnoozeTimerSheet(timeDuration: $viewModel.snoozeDuration)
                        .fittedPresentationDetent()
                case .date:
                    DatePicker("Select Date",
                               selection: $viewModel.date,
                               displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .fittedPresentationDetent()
                case .symbolAndColor:
                    SymbolSheet(selectedIcon: $viewModel.icon,
                                color: $viewModel.color)
                    .presentationDetents([.fraction(0.5), .height(.totalHeight - imageFrame.maxY)])
                    .presentationDragIndicator(.automatic)
                    .presentationBackground(.clear)
                }
            }
            .navigationTransition(.zoom(sourceID: sheet, in: animation))
        }
        .fullScreenCover(item: $viewModel.fullScreenPresentation) { fullScreenPresentation in
            switch fullScreenPresentation {
            case .symbolSheet:
                EmojiSelectorView(color: viewModel.color, topPadding: 0) { [weak viewModel] symbol in
                    viewModel?.fullScreenPresentation = nil
                    viewModel?.icon = symbol
                }
                .ignoresSafeArea(edges: .vertical)
            }
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
            case .symbolAndColor:
                fatalError("\(presentation.rawValue) has no symbol")
            }
        }
        
    }
}

#Preview {
    CreateReminderView(store: .init())
}
