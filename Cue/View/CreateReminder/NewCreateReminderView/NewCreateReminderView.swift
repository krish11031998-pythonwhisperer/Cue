//
//  NewCreateReminderView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 20/05/2026.
//

import VanorUI
import SwiftUI
import Model

fileprivate struct CueItListSection: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowBackground(Color.clear)
            .listRowInsets(.all, .zero)
            .listSectionMargins(.top, 0)
            .listRowSeparatorTint(.cueItBackground)
    }
}

fileprivate extension View {
    func cueItListSection() -> some View {
        modifier(CueItListSection())
    }
}

struct NewCreateReminderView: View {
 
    typealias Mode = NewCreateReminderViewModel.Mode
    
    @State private var viewModel: NewCreateReminderViewModel
    @FocusState var textFieldIsFocused: Bool
    @Environment(\.dismiss) var dismiss
    private var dismissActionFromParent: Callback?
    
    init(mode: Mode, store: Store, dismissActionFromParent: Callback? = nil) {
        self.viewModel = .init(store: store, mode: mode)
        self.dismissActionFromParent = dismissActionFromParent
    }
    
    var options: [ReminderOptionConfig] {
        ReminderEditField.allCases.map { $0.config(viewModel) }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ReminderTitleView(viewModel: $viewModel, textFieldIsFocused: $textFieldIsFocused) {
                    textFieldIsFocused = false
                    self.viewModel.presentation = .emojiAndColorPicker
                } autoDismiss: {
                    // Dismiss
                    self.textFieldIsFocused = false
                }
                .onGeometryChange(for: CGRect.self,
                                  of: { $0.frame(in: .global) },
                                  action: { [weak viewModel] in viewModel?.imageFrame = $0 })
                .padding(.top, viewModel.edittingMode ? 24 : 0)
                
                VStack(alignment: .center, spacing: 6) {
                    ForEach(ReminderEditField.allCases) { editFeild in
                        switch editFeild {
                        case .date, .time, .repeat:
                            ReminderOptionView(config: editFeild.config(viewModel))
                        case .alarm:
                            ReminderOptionView(config: editFeild.config(viewModel)) {
                                if viewModel.alarmIsOn {
                                    ActionButtonListRow(config: .init(symbol: .zzz, label: String.formattedTimelineInterval(viewModel.snoozeDuration), action: {
                                        viewModel.presentation = .snoozeDuration
                                    }))
                                }
                            }
                            .animation(.easeInOut, value: viewModel.alarmIsOn)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .padding(.top, 14)
                .padding(.bottom, 14)
                
                Section {
                    ReminderTagView(tags: viewModel.tags) {
                        viewModel.presentation = .tag
                    }
                    .padding(.bottom, 14)
                } header: {
                    Text("Tags")
                        .font(.headline)
                        .fontWeight(.medium)
                        .padding(.top, 14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                CreateReminderTasksView(canLoadSuggestions: viewModel.canLoadSuggestions,
                                        isLoadingSuggestions: viewModel.isLoadingSuggestions,
                                        taskViewModels: viewModel.taskViewModels){ [weak viewModel] taskName in
                    withAnimation(.easeInOut) {
                        textFieldIsFocused = false
                        viewModel?.addTask(title: taskName)
                    }
                } generateTasks: { [weak viewModel] in
                    textFieldIsFocused = false
                    viewModel?.suggestionSubtasks()
                }
            }
            .padding(.horizontal, 20)
        }
        .animation(.easeInOut, value: viewModel.taskViewModels)
        .sheet(item: $viewModel.presentation, content: { presentation in
            switch presentation {
            case .emojiAndColorPicker:
                SymbolSheet(colors: .defaultColors,
                            colorSelector: .grid,
                            selectedIcon: $viewModel.icon,
                            color: $viewModel.color)
                .presentationDetents([.fraction(0.5), .height(.totalHeight - viewModel.imageFrame.maxY - 24)])
                .presentationDragIndicator(.automatic)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.5)))
                .presentationContentInteraction(.resizes)
            case .calendar:
                DatePickerView.date("Reminder Start Date", date: $viewModel.date)
                    .fittedPresentationDetent()
            case .scheduleBuilder:
                ReminderWeekPlannerView(selectedDays: viewModel.scheduleBuilder.weekdays ?? [], weekInterval: viewModel.scheduleBuilder.intervalWeek ?? 1, datesInMonth: viewModel.scheduleBuilder.dates ?? [], reminderType: viewModel.scheduleBuilder.dates != nil ? .monthly : .weekly) { [weak viewModel] in
                    viewModel?.scheduleBuilder = $0
                }
                .fittedPresentationDetent()
            case .snoozeDuration:
                TimerSheetView(timeDuration: $viewModel.snoozeDuration, title: "Snooze Duration", bound: .hour)
                    .fittedPresentationDetent()
            case .timeSheet:
                DatePickerView.time("Remind me at", date: $viewModel.timeDate, notification: $viewModel.reminderNotification)
                    .fittedPresentationDetent()
            case .tag:
                TagView(preSelected: viewModel.tags) { [weak viewModel] in
                    viewModel?.tags = $0
                }
                .presentationDetents([.large])
            }
        })
        .background(alignment: .center) {
            Color.cueItBackground
                .ignoresSafeArea(.all)
        }
        .safeAreaInset(edge: .bottom, alignment: .center, spacing: 0, content: {
            HStack(alignment: .center, spacing: 12) {
                Button {
                    viewModel.createReminder()
                    dismissSheet()
                } label: {
                    Image(systemSymbol: .checkmark)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Color.white)
                        .frame(width: 44, height: 44, alignment: .center)
                        .glassEffect(.regular.interactive(true).tint(viewModel.color.baseColor), in: .circle)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canCreateReminder)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .trailing)
        })
        .environment(\.theme, viewModel.theme)
        
    }
    
    private func dismissSheet() {
        if let dismissActionFromParent {
            dismissActionFromParent()
        } else {
            dismiss()
        }
    }
}

extension NewCreateReminderView {
    enum ReminderEditField: CaseIterable, Identifiable {
        case date
        case time
        case `repeat`
        case alarm
        
        var id: String {
            switch self {
            case .date:
                return "date"
            case .time:
                return "time"
            case .repeat:
                return "repeat"
            case .alarm:
                return "alarm"
            }
        }
        
        func config(_ viewModel: NewCreateReminderViewModel) -> ReminderOptionConfig {
            switch self {
            case .date:
                let dateAction: ActionButtonListRow.Config = .init(symbol: .calendarBadge, label: viewModel.dateString) {
                    // Present Calendar Sheet
                    viewModel.presentation = .calendar
                }
                
                return .init(title: "Date", actions: [.button(dateAction)])
            case .time:
                let startTime: ActionButtonListRow.Config  = .init(title: viewModel.timeString) {
                    // present time sheet
                    viewModel.presentation = .timeSheet
                }
                
                return .init(title: "Time", actions: [.button(startTime)])
            case .repeat:
                let repeatAction = ActionButtonListRow.Config(symbol: .arrow2Squarepath, label: viewModel.scheduleString) {
                    // Present `Repeat Sheet`
                    viewModel.presentation = .scheduleBuilder
                }
                return .init(title: "Repeat", actions: [.button(repeatAction)])
            case .alarm:
                let alarm = ActionToggleListRow.Config(content: viewModel.alarmIsOn) { newValue in
                    viewModel.alarmIsOn = newValue
                }
                return .init(title: "Alarm", actions: [.toggle(alarm)])
            }
        }
    }
}

#Preview {
    NewCreateReminderView(mode: .create, store: .init(), dismissActionFromParent: nil)
}
