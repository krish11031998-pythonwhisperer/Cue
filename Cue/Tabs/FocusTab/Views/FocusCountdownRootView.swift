//
//  FocusCountdownRootView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 01/06/2026.
//

import SwiftUI
import VanorUI
import Model

@MainActor
@Observable
class FocusCountdownRootViewModel {
    
    static let translationsXThreshold: CGFloat = 100
    
    enum TimerType: Identifiable, Equatable {
        case focus
        case reminder(ReminderModel)
        
        var id: String {
            switch self {
            case .focus:
                return "focus"
            case .reminder(let reminderModel):
                return "reminder_\(reminderModel.title)"
            }
        }
        
        var icon: Icon {
            switch self {
            case .focus:
                return .symbol(.timer)
            case .reminder(let reminderModel):
                return .init(reminderModel.icon)!
            }
        }
        
        var title: String {
            switch self {
            case .focus:
                return "Focus"
            case .reminder(let reminderModel):
                return reminderModel.title
            }
        }
    }
    
    var timerItems: [TimerType] = [.focus]
    var selectedTimerItem: TimerType = .focus
    @ObservationIgnored
    var currentSelectedReminderIdx: Int = 0
    var panGestureTranslation: CGFloat = 0
    

    init(reminders: [ReminderModel]) {
        self.selectedTimerItem = .focus
        self.timerItems = [.focus] + reminders.map { .reminder($0) }
    }
    
    convenience init() {
        self.init(reminders: [])
    }
    
    
    func updateSelectedReminder(forwards: Bool, backwards: Bool) {
        if forwards && currentSelectedReminderIdx < timerItems.count - 1 {
            currentSelectedReminderIdx += 1
        } else if backwards && currentSelectedReminderIdx > 0 {
            currentSelectedReminderIdx -= 1
        } else {
            withAnimation(.snappy) {
                self.panGestureTranslation = 0
            }
        }
        
        self.selectedTimerItem = timerItems[currentSelectedReminderIdx]
    }
    
    func updateWithReminders(_ reminders: [ReminderModel]) {
        var newUpdatedItems: [TimerType] = [.focus]
        reminders.forEach { reminder in
            newUpdatedItems.append(.reminder(reminder))
        }
        self.timerItems = newUpdatedItems
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

struct FocusCountdownRootView: View {

    @Bindable private var coordinator: FocusTimerLaunchControlCoordinator
    @State private var viewModel: FocusCountdownRootViewModel = .init()
    let reminders: [ReminderModel]
    @Environment(\.colorScheme) var colorScheme
    
    init(coordinator: FocusTimerLaunchControlCoordinator, reminders: [ReminderModel]) {
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
    
    private var gestureRecognizerEnabled: Bool {
        coordinator.state == .idle || coordinator.state == .reset
    }
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            
            ZStack(alignment: .center) {
                FocusCountdownTopGradient()
                    .fill(radialGradient(width: size.width))
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: size.width, alignment: .center)
                    .position(x: size.width.half, y: size.width.half)
                    .blur(radius: 15)
                    .ignoresSafeArea(edges: .top)
                
                FocusCountdownTimerView()
                    .environment(viewModel)
                    .environment(coordinator)
                    .padding(.horizontal, 8)
                    .position(x: size.width.half, y: size.width * 0.7)
            }
        }
        .sensoryFeedback(.selection, trigger: viewModel.selectedTimerItem)
        .gesture(DragPopGesture(isEnabled: gestureRecognizerEnabled, translation: dragGestureHandler, hasEnded: hasEnded))
        .safeAreaBar(edge: .top, alignment: .center, spacing: 8) {
            FocusReminderCarouselSelectorView(selectedItem: viewModel.selectedTimerItem, items: viewModel.timerItems)
                .fixedSize(horizontal: false, vertical: true)
                .disabled(true)
        }
        .safeAreaBar(edge: .bottom, alignment: .center, spacing: 8) {
            FloatingFocusTimerFooterView(viewModel: viewModel, coordinator: coordinator)
        }
        .onChange(of: viewModel.selectedTimerItem, initial: true) { _, newValue in
            guard case .reminder(let reminderModel) = newValue else { return }
            let tasks = reminderModel.tasks
            coordinator.numberOfTasks = tasks.count
        }
        .onChange(of: reminders, initial: true) { oldValue, newValue in
            viewModel.updateWithReminders(newValue)
        }
    }
    
    private func dragGestureHandler(_ point: CGPoint) {
        let x = point.x
        guard abs(x) > 0 else {
            withAnimation(.snappy) {
                viewModel.panGestureTranslation = 0
            }
            return
        }
        let diff = min(1, max(0, abs(x)/FocusCountdownRootViewModel.translationsXThreshold))
        #if DEBUG
//        print("(DEBUG) diff: ", diff)
        #endif
        viewModel.panGestureTranslation = diff
    }
    
    private func hasEnded(_ point: CGPoint) {
        let x = point.x
        guard abs(x) > FocusCountdownRootViewModel.translationsXThreshold else {
            withAnimation(.snappy) {
                self.viewModel.panGestureTranslation = 0
            }
            return
        }
        viewModel.updateSelectedReminder(forwards: x < 0, backwards: x > 0)
    }
    
    
    // MARK: - Floating Focus Timer View
    
    struct FloatingFocusTimerFooterView: View {
        
        private var viewModel: FocusCountdownRootViewModel
        @Bindable private var coordinator: FocusTimerLaunchControlCoordinator
        
        init(viewModel: FocusCountdownRootViewModel, coordinator: FocusTimerLaunchControlCoordinator) {
            self.viewModel = viewModel
            self.coordinator = coordinator
        }
        
        var body: some View {
            ZStack(alignment: .center) {
                switch coordinator.state {
                case .idle, .reset:
                    FocusTimerLaunchControl(coordinator: coordinator) {
                        // Present Sheet
                        print("(DEBUG) present sheet with reminders")
                    }
                    .transition(.popIn)
                case .pause, .resume, .start:
                    HStack(alignment: .center, spacing: 8) {
                        ReminderIconView(icon: viewModel.selectedTimerItem.icon,
                                         foregroundColor: .primary,
                                         backgroundColor: Color.secondarySystemBackground,
                                         font: .caption)
                        .frame(width: 32, height: 32, alignment: .center)
                        Text(viewModel.selectedTimerItem.title)
                            .font(.headline.weight(.semibold))
                        Spacer()
                        
                        LaunchControlButton(image: .lockAppDashed, size: .regular) {
                            // Disable App Blocking
                        }
                        
                        LaunchControlButton(image: .alarmWavesLeftAndRight, size: .regular) {
                            // Diable Alarm
                        }
                    }
                    .transition(.popIn)
                }
            }
            .padding(.bottom, 8)
            .padding(.horizontal, 20)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    @Previewable @State var coordinator: FocusTimerLaunchControlCoordinator = .init(alarmCoordinator: nil)
    FocusCountdownRootView(coordinator: coordinator, reminders: [.exampleOne(), .exampleTwo(), .exampleThree(), .exampleFour()])
        .safeAreaBar(edge: .bottom) {
            FocusTimerLaunchControl(coordinator: coordinator) {
                //
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 20)
        }
}
