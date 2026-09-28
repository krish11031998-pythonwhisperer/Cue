//
//  RoutineDetailView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 26/09/2026.
//

import SwiftUI
import VanorUI
import Model
import FamilyControls

internal struct RoutineDetailViewSection: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.init(top: 20, leading: 20, bottom: 20, trailing: 20))
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(RowBackground())
            .clipShape(RoundedRectangle(cornerRadius: 32))
    }
}

internal struct RoutineDetailGroupBox: GroupBoxStyle {
    
    enum Style {
        case `default`
        case themed(LCHColor)
    }
    
    let style: Style
    
    func makeBody(configuration: Configuration) -> some View {
        switch style {
        case .default:
            VStack(alignment: .leading, spacing: 12) {
                configuration.label
                configuration.content
            }
            .padding(.init(top: 20, leading: 20, bottom: 20, trailing: 20))
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(RowBackground())
            .clipShape(RoundedRectangle(cornerRadius: 32))
        case .themed(let theme):
            VStack(alignment: .leading, spacing: 12) {
                configuration.label
                configuration.content
            }
            .padding(.init(top: 20, leading: 20, bottom: 20, trailing: 20))
            .frame(maxWidth: .infinity, alignment: .leading)
            .clipped()
            .background(alignment: .center) {
                RoundedRectangle(cornerRadius: 32)
                    .fill(theme.surfaceSecondary)
                    .stroke(theme.outlinePrimary, style: .init(lineWidth: 1))
            }
        }
    }
}


struct RoutineDetailView: View {

    @Environment(Store.self) var store
    @Environment(\.dismiss) var dismiss
    @State private var viewModel: RoutineDetailViewModel
    init(routine: ReminderModel) {
        self._viewModel = .init(initialValue: .init(routine))
    }
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .center, spacing: 24) {
                RoutineHeaderView(model: viewModel.headerConfig)
                if viewModel.steps.isEmpty {
                    Button {
                        self.viewModel.presentation = .editRoutine(viewModel.routine)
                    } label: {
                        RoutineEmptyStepsView()
                    }
                    .buttonStyle(.plain)
                } else {
                    RoutineStepsView(model: .init(steps: viewModel.steps))
                }
                
                if let focusSessionConfig = viewModel.focusSessionConfig {
                    RoutineDetailFocusSessionCard(config: focusSessionConfig)
                } else {
                    Button {
                        self.viewModel.presentation = .createFocusSession(viewModel.routine)
                    } label: {
                        RoutineDetailCreateFocusCard()
                    }
                }
                RoutineCalendarView(model: .init(month: Date.now.month, schedule: nil, calendarDay: viewModel.daysInCalendar, color: viewModel.routine.color))
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(alignment: .center) {
            Color.cueItBackground
                .ignoresSafeArea()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit", systemSymbol: .pencil) {
                        self.viewModel.presentation = .editRoutine(viewModel.routine)
                    }
                    
                    Button("Delete", systemSymbol: .trash, role: .destructive) {
                        self.viewModel.showDeleteAlert = true
                    }
                } label: {
                    Image(systemSymbol: .ellipsis)
                }
            }
        }
        .alert("Delete Routine?", isPresented: $viewModel.showDeleteAlert) {
            Button("Delete", role: .destructive) {
                self.viewModel.deleteRoutine()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(viewModel.routine.title)\"? This can't be undone.")
        }
        .sheet(item: $viewModel.presentation, content: { presentation in
            switch presentation {
            case .editRoutine(let routine):
                presentEditRoutine(routine)
            case .createFocusSession(let routine):
                presentCreateFocusSession(routine)
            }
        })
        .task {
            viewModel.store = store
            await viewModel.fetchRoutineLogs()
        }
        .environment(\.theme, .init(color: viewModel.routine.color))
    }
    
    @ViewBuilder
    private func presentEditRoutine(_ routine: ReminderModel) -> some View {
        let mode = NewCreateReminderView.Mode.edit(routine) { @MainActor newRoutine in
            self.viewModel.routine = newRoutine
        }
        
        NewCreateReminderView(mode: mode, store: store)
    }
    
    @ViewBuilder
    private func presentCreateFocusSession(_ routine: ReminderModel) -> some View {
        let mode = CreateFocusSessionSheet.Mode.createFromRoutine(routine.title) { @MainActor focusSessionModel in
            guard let focusSessionModel else { return }
            self.viewModel.updateFocusSession(with: focusSessionModel)
        }
        
        CreateFocusSessionSheet(mode: mode)
    }
}

#Preview("RoutineDetail (without FocusSession)") {
    RoutineDetailView(routine: .exampleFive())
        .environment(Store())
}

#Preview("RoutineDetail (with FocusSession)") {
    RoutineDetailView(routine: .exampleSix())
        .environment(Store())
}

#Preview("RoutineDetail (with FocusSession)") {
    RoutineDetailView(routine: .exampleSeven())
        .environment(Store())
}
