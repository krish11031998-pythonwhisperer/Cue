//
//  CreateReminderView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 18/01/2026.
//

import SwiftUI
import VanorUI
import Model
internal import EmojiKit

struct CreateReminderView: View {
    
    enum Mode: Equatable {
        case create
        case edit(ReminderModel)
    }

    @State private var viewModel: CreateReminderViewModel
    @Namespace private var animation
    @Environment(\.dismiss) var dismiss
    @FocusState var textFieldIsFocused: Bool
    private let mode: Mode
    
    init(mode: Mode, store: Store) {
        self.mode = mode
        self._viewModel = .init(initialValue: .init(store: store))
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    CreateReminderImageButton(color: viewModel.color,
                                              icon: viewModel.icon) {
                        viewModel.presentation = .symbolAndColor
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 108, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 32)
                    .onGeometryChange(for: CGRect.self,
                                      of: { $0.frame(in: .global) },
                                      action: { viewModel.imageFrame = $0 })
                    
                    TextField("What would you like to be reminded of?",
                              text: $viewModel.reminderTitle,
                              axis: .vertical)
                    .font(.title3)
                    .fontWeight(.medium)
                    .focused($textFieldIsFocused)
                    
                    OverFlowingHorizontalLayout(horizontalSpacing: 8, verticalSpacing: 10) {
                        ForEach(CreateReminderViewModel.ReminderCalendarPresentation.allCases) { presentation in
                            ReminderButton(presentation: presentation,
                                           buttonTitle: viewModel.buttonTitleForElement(presentation),
                                           animation: animation) { presentation in
                                self.viewModel.presentation = presentation
                            }
                        }
                    }
                    .padding(.top, 12)
                    
                    CreateReminderTasksView(canLoadSuggestions: viewModel.canLoadSuggestions, isLoadingSuggestions: viewModel.isLoadingSuggestions,
                                            taskViewModels: viewModel.taskViewModels) { taskName in
                        withAnimation(.easeInOut) {
                            textFieldIsFocused = false
                            viewModel.addTask(title: taskName)
                        }
                    } deleteTask: { _ in
                        print("(DEBUG) tapped on delete")
                    } generateTasks: {
                        textFieldIsFocused = false
                        viewModel.suggestionSubtasks()
                    }
                    .padding(.top, 32)
                    .animation(.default, value: viewModel.taskViewModels)

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
                    .disabled(!viewModel.canCreateReminder)
                }
            }
        }
        .sheet(item: $viewModel.presentation) { sheet in
            Group {
                switch sheet {
                case .alarmAt:
                    DatePickerView(date: $viewModel.timeDate, viewType: .time("Reminder me at", .alarmFill))
                    .fittedPresentationDetent()
                case .duration:
                    TimerSheetView(timeDuration: $viewModel.snoozeDuration, title: "Snooze Duration", bound: .hour)
                        .fittedPresentationDetent()
                case .date:
                    DatePickerView(date: $viewModel.date, viewType: .date("Reminder Start Date", .calendar))
                    .fittedPresentationDetent()
                case .repeat:
                    ReminderWeekPlannerView(selectedDays: viewModel.scheduleBuilder.weekdays ?? [], weekInterval: viewModel.scheduleBuilder.intervalWeek ?? 1, datesInMonth: viewModel.scheduleBuilder.dates ?? [], reminderType: viewModel.scheduleBuilder.dates != nil ? .monthly : .weekly) {
                        viewModel.scheduleBuilder = $0
                    }
                        .fittedPresentationDetent()
                case .symbolAndColor:
                    SymbolSheet(selectedIcon: $viewModel.icon,
                                color: $viewModel.color)
                    .presentationDetents([.fraction(0.5), .height(.totalHeight - viewModel.imageFrame.maxY)])
                    .presentationDragIndicator(.automatic)
                    .presentationBackground(.clear)
                    .presentationContentInteraction(.resizes)
                }
            }
            .navigationTransition(.zoom(sourceID: sheet, in: animation))
        }
        .fullScreenCover(item: $viewModel.fullScreenPresentation) { fullScreenPresentation in
            switch fullScreenPresentation {
            case .symbolSheet:
                SymbolSelectorView(color: viewModel.color, topPadding: 0, searchText: "") { [weak viewModel] symbol in
                    viewModel?.fullScreenPresentation = nil
                    viewModel?.icon = symbol
                }
                .ignoresSafeArea(edges: .vertical)
            }
        }
        .task(id: mode) {
            guard case .edit(let reminderModel) = mode else {
                return
            }
            viewModel.updateBasedOnMode(reminderModel: reminderModel)
        }
    }
    
    
    // MARK: - ReminderButton
    
    struct ReminderButton: View {
        
        let presentation: CreateReminderViewModel.ReminderCalendarPresentation
        let buttonTitle: String
        var animation: Namespace.ID
        let action: (CreateReminderViewModel.ReminderCalendarPresentation) -> Void
        
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
                .padding(.init(top: 6, leading: 8, bottom: 6, trailing: 8))
                .background(Color.backgroundSecondary, in: .capsule)
            }
            .buttonStyle(.plain)
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
            case .repeat:
                return .arrow2Squarepath
            case .symbolAndColor:
                fatalError("\(presentation.rawValue) has no symbol")
            }
        }
    }
    
    
    // MARK: - DatePickerView
    
    struct DatePickerView: View {
        enum ViewType {
            case time(String, SFSymbol)
            case date(String, SFSymbol)
            
            var title: String {
                switch self {
                case .time(let string, _):
                    return string
                case .date(let string, _):
                    return string
                }
            }
            
            var symbol: SFSymbol {
                switch self {
                case .time(_, let sFSymbol):
                    return sFSymbol
                case .date(_, let sFSymbol):
                    return sFSymbol
                }
            }
        }
        
        @Binding var date: Date
        let viewType: ViewType
        
        var body: some View {
            VStack(alignment: .center, spacing: 16) {
                Label(viewType.title, systemSymbol: viewType.symbol)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.top, 32)
                
                Group {
                    switch viewType {
                    case .time:
                        DatePicker(selection: $date, displayedComponents: [.hourAndMinute]) {
                            Text("DatePicker")
                        }
                        .datePickerStyle(.wheel)
                    case .date:
                        DatePicker(selection: $date, displayedComponents: [.date]) {
                            Text("DatePicker")
                        }
                        .datePickerStyle(.graphical)
                    }
                }
                .labelsHidden()
            }
        }
        
    }
}

#Preview {
    CreateReminderView(mode: .create, store: .init())
}
