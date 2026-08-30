//
//  FTQuickStartView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 01/06/2026.
//

import SwiftUI
import VanorUI
import Model
import FamilyControls

extension FamilyActivitySelection {
    var isEmpty: Bool {
        self.applications.isEmpty && self.categories.isEmpty && self.webDomains.isEmpty
    }
}

struct FocusCountdownTopGradient: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: .init(x: rect.minX, y: rect.minY))
            path.addLine(to: .init(x: rect.maxX, y: rect.minY))
            path.addQuadCurve(to: .init(x: rect.minX, y: rect.minY), control: .init(x: rect.midX, y: rect.maxY * 0.45))
        }
    }
}

struct FTQuickStartView: View {

    @Bindable private var coordinator: FocusSessionCoordinator
    @State private var viewModel: FTQuickStartViewModel = .init()
    let reminders: [ReminderModel]
    @Environment(\.colorScheme) var colorScheme
    
    init(coordinator: FocusSessionCoordinator, reminders: [ReminderModel]) {
        self.coordinator = coordinator
        self.reminders = reminders
    }
    
    var appTheme: LCHColor {
        Color.proSky
    }
    
    private func radialGradient(width: CGFloat) -> RadialGradient {
        switch colorScheme {
        case .light:
            RadialGradient(colors: [appTheme.baseColor.opacity(0.5), appTheme.baseColor.opacity(0.3), appTheme.baseColor.opacity(0.1), appTheme.baseColor.opacity(0)], center: .center, startRadius: 0, endRadius: width)
        case .dark:
            RadialGradient(colors: [appTheme.baseColor.opacity(1), appTheme.baseColor.opacity(0.5), appTheme.baseColor.opacity(0.2), appTheme.baseColor.opacity(0)], center: .center, startRadius: 0, endRadius: width)
        @unknown default:
            RadialGradient(colors: [appTheme.baseColor.opacity(0.5), appTheme.baseColor.opacity(0.3), appTheme.baseColor.opacity(0.1), appTheme.baseColor.opacity(0)], center: .center, startRadius: 0, endRadius: width)
        }
    }
    
    private var defaultColor: Color {
        switch colorScheme {
        case .light:
            Color.waveformColorOne
        case .dark:
            Color.waveformDarkColorOne
        @unknown default:
            Color.waveformColorOne
        }
    }
    
    private var gestureRecognizerEnabled: Bool {
        coordinator.state == .idle || coordinator.state == .reset
    }
    
    private var linearGradientBackground: some View {
        let mainColor: LCHColor
        switch viewModel.selectedTimerItem {
        case .focus:
            mainColor = .init(color: defaultColor)
        case .reminder(let reminderModel):
            mainColor = .init(color: reminderModel.color)
        }
        
        return LinearGradient(stops: [
            .init(color: mainColor.backgroundPrimary, location: 0),
            .init(color: mainColor.backgroundPrimary.opacity(0.6), location: 0.1),
            .init(color: mainColor.backgroundPrimary.opacity(0.3), location: 0.2),
            .init(color: mainColor.backgroundPrimary.opacity(0.1), location: 0.5)],
                       startPoint: .top,
                       endPoint: .bottom)
    }
    
    var body: some View {
        FTSessionView(coordinator: coordinator, viewType: .quickStart) {
            GeometryReader { proxy in
                let size = proxy.size
                
                ZStack(alignment: .center) {
                    Color.cueItBackground
                        .ignoresSafeArea(edges: .vertical)
                    
                    FocusCountdownTimerView()
                        .environment(viewModel)
                        .environment(coordinator)
                        .padding(.horizontal, 8)
                        .position(x: size.width.half, y: size.width * 0.7)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: viewModel.selectedTimerItem)
        .gesture(DragPopGesture(isEnabled: gestureRecognizerEnabled, translation: dragGestureHandler, hasEnded: hasEnded))
        .safeAreaBar(edge: .top, alignment: .center, spacing: 8) {
            FocusReminderCarouselSelectorView(selectedItem: viewModel.selectedTimerItem, items: viewModel.timerItems)
                .fixedSize(horizontal: false, vertical: true)
                .disabled(true)
        }
        .sheet(isPresented: $coordinator.showTasksSheet, onDismiss: {
            self.viewModel.sessionTaskPresentationDetent = .medium
        }) {
            OngoingSessionOverviewSheet(selectedPresentationDetent: viewModel.sessionTaskPresentationDetent)
                .environment(coordinator)
                .presentationDetents([.medium, .large], selection: $viewModel.sessionTaskPresentationDetent)
                .presentationContentInteraction(.resizes)
                .interactiveDismissDisabled(true)
                .presentationDragIndicator(.hidden)
        }
        .onChange(of: viewModel.selectedTimerItem, initial: true) { _, newValue in
            coordinator.reminderModel = viewModel.selectedReminder()
            coordinator.sessionAttributes = viewModel.focusSessionAttributes()
            coordinator.shieldConfiguration = viewModel.appShieldConfiguration()
        }
        .onChange(of: reminders, initial: true) { oldValue, newValue in
            viewModel.updateWithReminders(newValue)
        }
        .environment(\.theme, viewModel.selectedTimerItem.theme)
    }
    
    private func dragGestureHandler(_ point: CGPoint) {
        let x = point.x
        guard abs(x) > 0 else {
            withAnimation(.snappy) {
                viewModel.panGestureTranslation = 0
            }
            return
        }
        let diff = min(1, max(0, abs(x)/FTQuickStartViewModel.translationsXThreshold))
        viewModel.panGestureTranslation = diff
    }
    
    private func hasEnded(_ point: CGPoint) {
        let x = point.x
        guard abs(x) > FTQuickStartViewModel.translationsXThreshold else {
            withAnimation(.snappy) {
                self.viewModel.panGestureTranslation = 0
            }
            return
        }
        viewModel.updateSelectedReminder(forwards: x < 0, backwards: x > 0)
    }
}

#Preview {
    @Previewable @State var coordinator: FocusSessionCoordinator = .init(alarmCoordinator: nil, liveActivityCoordinator: nil, appShieldCoordinator: nil, storeCoordinator: nil)
    // NOTE: the launch control is already rendered by FTQuickStartView's own bottom
    // footer (FloatingFocusTimerFooterView), so the previous `.safeAreaBar` overlay
    // here was a duplicate and has been removed.
    FTQuickStartView(coordinator: coordinator, reminders: [.exampleOne(), .exampleTwo(), .exampleThree(), .exampleFour()])
}
