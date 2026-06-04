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
    
    typealias Mode = CreateReminderViewModel.Mode
    
    @Environment(SubscriptionManager.self) var subscriptionManager
    @State private var viewModel: CreateReminderViewModel
    @Namespace private var animation
    @Environment(\.dismiss) var dismiss
    @FocusState var textFieldIsFocused: Bool
    private var dismissActionFromParent: Callback?
    private let mode: Mode
    
    init(mode: Mode, store: Store, dismissActionFromParent: Callback? = nil) {
        self.mode = mode
        self.viewModel = .init(store: store, mode: mode)
        self.dismissActionFromParent = dismissActionFromParent
    }
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 0) {
                CreateReminderImageButton(color: viewModel.color,
                                          icon: viewModel.icon) { [weak viewModel] in
                    viewModel?.calendarPresentation = .iconSelector
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(width: 108, alignment: .center)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 32)
                .onGeometryChange(for: CGRect.self,
                                  of: { $0.frame(in: .global) },
                                  action: { [weak viewModel] in viewModel?.imageFrame = $0 })
                
                TextField("What you'd like to be reminded of?",
                          text: $viewModel.reminderTitle,
                          axis: .vertical)
                .font(.title3)
                .fontWeight(.medium)
                .submitLabel(.go)
                .focused($textFieldIsFocused)
                .autoDismissOnReturn(text: $viewModel.reminderTitle) {
                    self.textFieldIsFocused = false
                }
                
                if let tagString = viewModel.tagString {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemSymbol: .tagFill)
                        Text(tagString)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                    }
                    .font(.footnote)
                    .foregroundStyle(Color.tertiaryText)
                    .padding(.top, 12)
                    .transition(.popIn)
                }
                
                OverFlowingHorizontalLayout(horizontalSpacing: 8, verticalSpacing: 10) {
                    ForEach(CreateReminderViewModel.ReminderCalendarPresentation.allCases) { presentation in
                        ReminderButton(presentation: presentation,
                                       buttonTitle: viewModel.buttonTitleForElement(presentation),
                                       animation: animation, action: presentReminderButtonTap(_:))
                    }
                }
                .padding(.top, 16)
                
                CreateReminderTasksView(canLoadSuggestions: viewModel.canLoadSuggestions,
                                        isLoadingSuggestions: viewModel.isLoadingSuggestions,
                                        taskViewModels: viewModel.taskViewModels) { [weak viewModel] taskName in
                    withAnimation(.easeInOut) {
                        textFieldIsFocused = false
                        viewModel?.addTask(title: taskName)
                    }
                } deleteTask: { _ in
                    print("(DEBUG) tapped on delete")
                } generateTasks: { [weak viewModel] in
                    textFieldIsFocused = false
                    viewModel?.suggestionSubtasks()
                }
                .padding(.top, 32)
                .animation(.default, value: viewModel.taskViewModels)
                
            }
            .padding(.horizontal, 20)
        }
        .toolbar {
            if subscriptionManager.userIsPro {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("", systemSymbol: .tagFill) { [weak viewModel] in
                        viewModel?.presentation = .tags
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .confirm) { [weak viewModel] in
                    viewModel?.createReminder()
                    if let dismissActionFromParent {
                        dismissActionFromParent()
                    } else {
                        self.dismiss()
                    }
                }
                .tint(Color.proSky.baseColor)
                .disabled(!viewModel.canCreateReminder)
            }
            
        }
        .sheet(item: $viewModel.calendarPresentation, onDismiss: onDismiss) { sheet in
            Group {
                switch sheet {
                case .alarmAt:
                    DatePickerView.time("Remind me at", date: $viewModel.timeDate, notification: $viewModel.reminderNotification)
                        .fittedPresentationDetent()
                case .duration:
                    TimerSheetView(timeDuration: $viewModel.snoozeDuration, title: "Snooze Duration", bound: .hour)
                        .fittedPresentationDetent()
                case .date:
                    DatePickerView.date("Reminder Start Date", date: $viewModel.date)
                        .fittedPresentationDetent()
                case .repeat:
                    ReminderWeekPlannerView(selectedDays: viewModel.scheduleBuilder.weekdays ?? [], weekInterval: viewModel.scheduleBuilder.intervalWeek ?? 1, datesInMonth: viewModel.scheduleBuilder.dates ?? [], reminderType: viewModel.scheduleBuilder.dates != nil ? .monthly : .weekly) { [weak viewModel] in
                        viewModel?.scheduleBuilder = $0
                    }
                    .fittedPresentationDetent()
                case .iconSelector:
                    SymbolSheet(selectedIcon: $viewModel.icon,
                                color: $viewModel.color)
                    .presentationDetents([.fraction(0.5), .height(.totalHeight - viewModel.imageFrame.maxY)])
                    .presentationDragIndicator(.automatic)
                    .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.5)))
                    .presentationContentInteraction(.resizes)
                }
            }
        }
        .sheet(item: $viewModel.presentation) { presentation in
            switch presentation {
            case .tags:
                TagView(preSelected: viewModel.tags) { [weak viewModel] in
                    viewModel?.tags = $0
                }
            }
        }
//        .task(id: mode) { [weak viewModel] in
//            guard case .edit(let reminderModel) = mode else {
//                return
//            }
//            viewModel?.updateBasedOnMode(reminderModel: reminderModel)
//        }
    }
    
    
    // MARK: - Helper Methods
    
    private func presentReminderButtonTap(_ presentation: CreateReminderViewModel.ReminderCalendarPresentation) {
        switch presentation {
        case .alarmAt:
            // Check for notification
            self.viewModel.calendarPresentation = presentation
        case .duration:
            // Check for alarm
            self.viewModel.calendarPresentation = presentation
        case .date, .repeat, .iconSelector:
            self.viewModel.calendarPresentation = presentation
        }
    }
    
    private func onDismiss() {
        switch viewModel.reminderNotification {
        case .alarm:
            viewModel.checkForPermissionForSettingAlarm()
        case .notification:
            viewModel.checkForPermissionForSendingNotification()
        default:
            fatalError("Shouldn't happen")
        }
    }
}

#Preview {
    CreateReminderView(mode: .create, store: .init())
}
