//
//  FocusTimerRootView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 01/06/2026.
//

import SwiftUI
import VanorUI
import Model

struct FocusCountdownTopGradient: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: .init(x: rect.minX, y: rect.minY))
            path.addLine(to: .init(x: rect.maxX, y: rect.minY))
            path.addQuadCurve(to: .init(x: rect.minX, y: rect.minY), control: .init(x: rect.midX, y: rect.maxY * 0.45))
        }
    }
}

struct FocusTimerRootView: View {

    @Bindable private var coordinator: FocusTimerLaunchControlCoordinator
    @State private var viewModel: FocusTimerRootViewModel = .init()
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
    
    private var linearGradientBackground: LinearGradient {
        let mainColor: LCHColor
        switch viewModel.selectedTimerItem {
        case .focus:
            mainColor = .init(color: defaultColor)
        case .reminder(let reminderModel):
            mainColor = .init(color: reminderModel.color)
        }
        
        return LinearGradient(stops: [.init(color: mainColor.backgroundTertiary, location: 0), .init(color: mainColor.backgroundSecondary, location: 0.37), .init(color: mainColor.backgroundPrimary, location: 0.67)], startPoint: .top, endPoint: .bottom)
    }
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            
            ZStack(alignment: .center) {
//                FocusCountdownTopGradient()
//                    .fill(radialGradient(width: size.width))
//                    .aspectRatio(1, contentMode: .fit)
//                    .frame(width: size.width, alignment: .center)
//                    .position(x: size.width.half, y: size.width.half)
//                    .blur(radius: 15)
//                linearGradientBackground
                Color.cueItBackground
                    .ignoresSafeArea(edges: .vertical)
                
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
        .sheet(item: $viewModel.sheetPresentation, content: { sheet in
            switch sheet {
            case .pomodoroSessionEditor:
                PomodoroSessionEditorView()
                    .fittedPresentationDetent()
            }
        })
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
        let diff = min(1, max(0, abs(x)/FocusTimerRootViewModel.translationsXThreshold))
        viewModel.panGestureTranslation = diff
    }
    
    private func hasEnded(_ point: CGPoint) {
        let x = point.x
        guard abs(x) > FocusTimerRootViewModel.translationsXThreshold else {
            withAnimation(.snappy) {
                self.viewModel.panGestureTranslation = 0
            }
            return
        }
        viewModel.updateSelectedReminder(forwards: x < 0, backwards: x > 0)
    }
    
    
    // MARK: - Floating Focus Timer View
    
    struct FloatingFocusTimerFooterView: View {
        
        private var viewModel: FocusTimerRootViewModel
        @Bindable private var coordinator: FocusTimerLaunchControlCoordinator
        
        init(viewModel: FocusTimerRootViewModel, coordinator: FocusTimerLaunchControlCoordinator) {
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
                        viewModel.presentAction(sessionType: coordinator.selectedTimerType)
                    }
                    .transition(.popIn)
                case .pause, .resume, .start:
                    Group {
                        switch coordinator.selectedTimerType {
                        case .classic:
                            ClassicFocusSessionTimerView(icon: viewModel.selectedTimerItem.icon, title: viewModel.selectedTimerItem.title)
                        case .pomodoro:
                            PomodoroFocusSessionTimerView(icon: viewModel.selectedTimerItem.icon,
                                                          title: viewModel.selectedTimerItem.title,
                                                          currentSessionIndex: coordinator.currentSessionIndex,
                                                          sessionCount: coordinator.pomodoroSessionCount)
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
    
    
    // MARK: - Classic Focus Session Timer View
    
    struct ClassicFocusSessionTimerView: View {
        let icon: Icon
        let title: String
        
        var body: some View {
            HStack(alignment: .center, spacing: 8) {
                ReminderIconView(icon: icon,
                                 foregroundColor: .primary,
                                 backgroundColor: Color.secondarySystemBackground,
                                 font: .caption)
                .frame(width: 32, height: 32, alignment: .center)
                
                Text(title)
                    .font(.headline.weight(.semibold))
                
                Spacer()
                
                LaunchControlButton(image: .lockAppDashed, size: .regular) {
                    // Disable App Blocking
                    return
                }
                
                LaunchControlButton(image: .alarmWavesLeftAndRight, size: .regular) {
                    // Diable Alarm
                    return
                }
            }
            .transition(.popIn)
        }
    }
    
    struct PomodoroFocusSessionTimerView: View {
        
        let icon: Icon
        let title: String
        let currentSessionIndex: Int
        let sessionCount: Int
        
        @ViewBuilder
        func capsule(for index: Int) -> some View {
            let theme: LCHColor = index % 2 == 0 ? Color.proSky : Color.proPlum
            if index < currentSessionIndex {
                Capsule()
                    .fill(theme.baseColor)
            } else if index == currentSessionIndex {
                Capsule()
                    .fill(theme.baseColor)
                    .animation(.easeInOut.repeatForever()) { content in
                        content
                            .opacity(index == currentSessionIndex ? 0.3 : 1)
                    }
            } else {
                Capsule()
                    .fill(theme.backgroundPrimary)
            }
        }
        
        var body: some View {
            VStack(alignment: .center, spacing: 4) {
                ClassicFocusSessionTimerView(icon: icon, title: title)
                
                HStack(alignment: .center, spacing: 2) {
                    ForEach(0..<(sessionCount + sessionCount - 1)) { index in
                        if index % 2 == 0 {
                            capsule(for: index)
                                .frame(height: 4)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            capsule(for: index)
                                .frame(width: 24, height: 4, alignment: .center)
                        }
                    }
                }
            }
        }
    }
    
    
}

#Preview {
    @Previewable @State var coordinator: FocusTimerLaunchControlCoordinator = .init(alarmCoordinator: nil)
    FocusTimerRootView(coordinator: coordinator, reminders: [.exampleOne(), .exampleTwo(), .exampleThree(), .exampleFour()])
        .safeAreaBar(edge: .bottom) {
            FocusTimerLaunchControl(coordinator: coordinator) {
                //
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 20)
        }
}
