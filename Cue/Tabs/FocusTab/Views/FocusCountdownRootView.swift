//
//  FocusCountdownRootView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 01/06/2026.
//

import SwiftUI
import VanorUI
import Model

#warning("Move this to VanorUI")
public struct DragPopGesture: UIGestureRecognizerRepresentable {

    let isEnabled: Bool
    let translation: (CGPoint) -> Void
    let hasEnded: (CGPoint) -> Void
    
    public init(isEnabled: Bool, translation: @escaping (CGPoint) -> Void, hasEnded: @escaping (CGPoint) -> Void) {
        self.isEnabled = isEnabled
        self.translation = translation
        self.hasEnded = hasEnded
    }
    
    public func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let panGesture = UIPanGestureRecognizer()
        return panGesture
    }
    
    public func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        recognizer.isEnabled = isEnabled
    }
    
    public func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        switch recognizer.state {
        case .began:
            print("(DEBUG) state: began")
            translation(.zero)
        case .cancelled:
            print("(DEBUG) state: cancelled")
            translation(.zero)
        case .failed:
            print("(DEBUG) state: failed")
            translation(.zero)
        case .possible:
            print("(DEBUG) state: possible")
            translation(.zero)
        case .changed:
            let translation = recognizer.translation(in: recognizer.view)
            print("(DEBUG) changed.translation: ", translation)
            self.translation(translation)
        case .ended:
            print("(DEBUG) ended.translation: ", translation)
            let translation = recognizer.translation(in: recognizer.view)
            self.hasEnded(translation)
        @unknown default:
            self.translation(.zero)
        }
    }
    
}


@MainActor
@Observable
class FocusCountdownRootViewModel {
    
    static let translationsXThreshold: CGFloat = 100
    
    let reminders: [ReminderModel]
    var selectedReminder: ReminderModel
    @ObservationIgnored
    var currentSelectedReminderIdx: Int = 0
    var panGestureTranslation: CGFloat = 0
    
    init(reminders: [ReminderModel]) {
        #warning("Need to add an warning to ensure that we will only show this view once we have some reminders")
        self._selectedReminder = reminders.first!
        self.reminders = reminders
    }
    
    
    func updateSelectedReminder(forwards: Bool, backwards: Bool) {
        if forwards && currentSelectedReminderIdx < reminders.count - 1 {
            currentSelectedReminderIdx += 1
        } else if backwards && currentSelectedReminderIdx > 0 {
            currentSelectedReminderIdx -= 1
        } else {
            withAnimation(.snappy) {
                self.panGestureTranslation = 0
            }
        }
        
        self.selectedReminder = reminders[currentSelectedReminderIdx]
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
    @State private var viewModel: FocusCountdownRootViewModel
    @Environment(\.colorScheme) var colorScheme
    
    init(coordinator: FocusTimerLaunchControlCoordinator, reminders: [ReminderModel]) {
        self.coordinator = coordinator
        self._viewModel = .init(initialValue: .init(reminders: reminders))
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
        .sensoryFeedback(.selection, trigger: viewModel.selectedReminder)
        .gesture(DragPopGesture(isEnabled: gestureRecognizerEnabled, translation: dragGestureHandler, hasEnded: hasEnded))
        .safeAreaBar(edge: .top, alignment: .center, spacing: 8) {
            FocusReminderCarouselSelectorView(selectedItem: viewModel.selectedReminder, reminders: viewModel.reminders)
                .fixedSize(horizontal: false, vertical: true)
                .disabled(true)
        }
        .safeAreaBar(edge: .bottom, alignment: .center, spacing: 8) {
            FloatingFocusTimerFooterView(viewModel: viewModel, coordinator: coordinator)
        }
        .onChange(of: viewModel.selectedReminder, initial: true) { oldValue, newValue in
            let tasks = newValue.tasks
            coordinator.numberOfTasks = tasks.count
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
                        ReminderIconView(icon: .init(viewModel.selectedReminder.icon)!,
                                         foregroundColor: .primary,
                                         backgroundColor: Color.secondarySystemBackground,
                                         font: .caption)
                        .frame(width: 32, height: 32, alignment: .center)
                        Text(viewModel.selectedReminder.title)
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
    @Previewable @State var coordinator: FocusTimerLaunchControlCoordinator = .init()
    FocusCountdownRootView(coordinator: coordinator, reminders: [.exampleOne(), .exampleTwo(), .exampleThree(), .exampleFour()])
        .safeAreaBar(edge: .bottom) {
            FocusTimerLaunchControl(coordinator: coordinator) {
                //
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 20)
        }
}
