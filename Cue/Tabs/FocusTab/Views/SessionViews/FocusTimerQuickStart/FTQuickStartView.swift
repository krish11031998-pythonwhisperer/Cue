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

    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.dismiss) var dismiss
    @Bindable private var coordinator: FocusSessionCoordinator
    @State private var viewModel: FTQuickStartViewModel = .init()
    @State private var isLandscape: Bool = false
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
    
    var `dualLayout`: Bool {
        switch horizontalSizeClass {
        case .compact:
            return false
        case .regular:
            switch verticalSizeClass {
            case .compact:
                return true
            case .regular:
                return isPhone ? isLandscape : false
            @unknown default:
                return true
            }
        @unknown default:
            return false
        }
    }

    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    var body: some View {
        Group {
            if !dualLayout {
                FTSessionView(coordinator: coordinator, viewType: .quickStart(delay: 0.4)) {
                    MainContentView(showsCarousel: true)
                }
                .sensoryFeedback(.selection, trigger: viewModel.selectedTimerItem)
                .gesture(DragPopGesture(isEnabled: gestureRecognizerEnabled, translation: dragGestureHandler, hasEnded: hasEnded))
            } else {
                HStack(alignment: .center, spacing: 0) {
                    FTSessionView(coordinator: coordinator, viewType: .quickStart(delay: 0.4)) {
                        ZStack(alignment: .center) {
                            Color.cueItBackground
                                .ignoresSafeArea()
                            if coordinator.session == nil {
                                VerticalSessionSelector(viewModel: viewModel)
                            } else {
                                OngoingSessionOverviewSheet()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    MainContentView(showsCarousel: false)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .onGeometryChange(for: Bool.self, of: { $0.size.width > $0.size.height }) { newValue in
            isLandscape = newValue
        }
        .environment(viewModel)
        .environment(coordinator)
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
    
    // MARK: Main Content
    
    struct MainContentView: View {
        @Environment(FocusSessionCoordinator.self) var coordinator
        @Environment(FTQuickStartViewModel.self) var viewModel
        let showsCarousel: Bool

        var body: some View {
            ZStack(alignment: .center) {
                Color.cueItBackground
                    .ignoresSafeArea(edges: .all)
                
                FocusCountdownTimerView()
                    .padding(.horizontal, 8)
            }
            .safeAreaBar(edge: .top, alignment: .center, spacing: 8) {
                TopCarouselView(isVisible: showsCarousel,
                                session: coordinator.session,
                                selectedTimerItem: viewModel.selectedTimerItem,
                                timerItems: viewModel.timerItems)
            }
            .animation(.snappy(duration: 0.3), value: coordinator.session == nil)
        }
        
    }
    
    // MARK: - Top Carousel View
    
    struct TopCarouselView: View {
        let isVisible: Bool
        let session: FocusSession?
        let selectedTimerItem: FTQuickStartViewModel.TimerType
        let timerItems: [FTQuickStartViewModel.TimerType]

        var body: some View {
            if session == nil && isVisible {
                FocusReminderCarouselSelectorView(selectedItem: selectedTimerItem, items: timerItems)
                    .fixedSize(horizontal: false, vertical: true)
                    .disabled(true)
                    .transition(.popIn.combined(with: .opacity))
            } else {
                EmptyView()
            }
        }
    }
    
    // MARK: - Vertical Session Selector
    
    struct VerticalSessionSelector: View {
        @Bindable private var viewModel: FTQuickStartViewModel
        
        init(viewModel: FTQuickStartViewModel) {
            self.viewModel = viewModel
        }
        
        var body: some View {
            ScrollView {
                LazyVStack(alignment: .center, spacing: 8) {
                    ForEach(viewModel.timerItems) { timerItem in
                        Button {
                            viewModel.selectedTimerItem = timerItem
                        } label: {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .center, spacing: 6) {
                                    ReminderIconView(icon: timerItem.icon, foregroundColor: .primary, backgroundColor: timerItem.theme.surfacePrimary, font: .subheadline)
                                        .frame(width: 44, height: 44, alignment: .center)
                                    Text(timerItem.title)
                                        .font(.headline)
                                        .foregroundStyle(timerItem.theme.foregroundSecondary)
                                }
                                
                                if case .reminder(let reminderModel) = timerItem, !reminderModel.tasks.isEmpty {
                                    Label {
                                        Text("\(reminderModel.tasks.count) Tasks")
                                    } icon: {
                                        Image(systemSymbol: .checkmark)
                                    }
                                    .labelStyle(SmallChipStyle(color: timerItem.theme.baseColor))
                                    .font(.caption.weight(.semibold))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(alignment: .center, content: {
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(viewModel.selectedTimerItem == timerItem ? timerItem.theme.backgroundTertiary : timerItem.theme.backgroundSecondary)
                                    .stroke(timerItem.theme.outlinePrimary, lineWidth: viewModel.selectedTimerItem == timerItem ? 0 : 1)
                                    .animation(.easeInOut, value: viewModel.selectedTimerItem == timerItem)
                            })
                        }
                        .buttonStyle(.defaultCueButton)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .scrollEdgeEffectStyle(.soft, for: .vertical)
        }
    }
}

#Preview {
    @Previewable @State var coordinator: FocusSessionCoordinator = .init(alarmCoordinator: nil, liveActivityCoordinator: nil, appShieldCoordinator: nil, storeCoordinator: nil)
    // NOTE: the launch control is already rendered by FTQuickStartView's own bottom
    // footer (FloatingFocusTimerFooterView), so the previous `.safeAreaBar` overlay
    // here was a duplicate and has been removed.
    FTQuickStartView(coordinator: coordinator, reminders: [.exampleOne(), .exampleTwo(), .exampleThree(), .exampleFour()])
        .environment(SubscriptionManager())
        .environment(Store())
        .frame(maxWidth: .infinity, alignment: .center)
}
