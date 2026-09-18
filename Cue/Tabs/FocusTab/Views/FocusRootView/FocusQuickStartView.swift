//
//  FocusQuickStartView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 12/09/2026.
//

import VanorUI
import Model
import SwiftUI

@Observable
@MainActor
public class FocusQuickViewModel: TimerAdjustmentManager {
   
    static let translationsXThreshold: CGFloat = 100
    static let defaultDuration: TimeInterval = 30 * 60
    typealias ItemModel = FocusQuickStartView.SelectedTimerInfo.Model
    
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
        
        var theme: LCHColor {
            switch self {
            case .focus:
                return Color.proSky
            case .reminder(let reminderModel):
                return .init(color: reminderModel.color)
            }
        }
        
        func itemModel(timerInterval: TimeInterval) -> ItemModel {
            switch self {
            case .focus:
                return .init(title: "Focus", theme: Color.proSky, timerDuration: timerInterval)
            case .reminder(let reminderModel):
                return .init(title: reminderModel.title, theme: .init(color: reminderModel.color), timerDuration: timerInterval)
            }
        }
    }
    
    enum ViewState: Equatable {
        case idle
        case withTimer(FocusQuickStartView.SelectedTimerInfo.Model)
        case transitioningBetweenReminders
    }
    
    private static let hourMark: TimeInterval = 60 * 60
    var timerItems: [TimerType] = [.focus]
    var timerDuration: TimeInterval = 30 * 60
    @ObservationIgnored
    var selectedTimerItem: TimerType = .focus {
        didSet {
            broadcastSelectedTimerItemChange()
        }
    }
    var panGestureTranslation: CGFloat = 0
    var state: ViewState = .idle
    @ObservationIgnored
    var currentSelectedReminderIdx: Int = 0
    var theme: LCHColor = Color.proSky
    
    
    var minBound: TimeInterval {
        5 * 60
    }
    
    var maxBound: TimeInterval {
        24 * Self.hourMark
    }

    var step: TimeInterval {
        if timerDuration < Self.hourMark {
            return 5 * 60
        } else {
            return 15 * 60
        }
    }
    
    func updateSelectedReminder(forwards: Bool, backwards: Bool) {
        guard !timerItems.isEmpty else { return }
        
        if forwards && currentSelectedReminderIdx < timerItems.count - 1 {
            currentSelectedReminderIdx += 1
        } else if backwards && currentSelectedReminderIdx > 0 {
            currentSelectedReminderIdx -= 1
        } else {
            withAnimation(.snappy) {
                self.panGestureTranslation = 0
            }
        }
        
        // `timerItems` can shrink while an index further down the list is selected.
        currentSelectedReminderIdx = min(currentSelectedReminderIdx, timerItems.count - 1)
        
        self.selectedTimerItem = timerItems[currentSelectedReminderIdx]
    }
    
    var selectedFocusSessionModel: FocusSessionModel {
        switch selectedTimerItem {
        case .focus:
            return .init(name: "Focus", sessionType: .classic, timerDuration: timerDuration, breakDuration: 0, blockedApps: nil, alarm: .off, sessionCount: nil, reminder: nil)
        case .reminder(let reminderModel):
            return .init(name: reminderModel.title, sessionType: .classic, timerDuration: timerDuration, breakDuration: 0, blockedApps: nil, alarm: .off, sessionCount: 0, reminder: reminderModel)
        }
    }
    
    // MARK: - Private Methods
    
    private func broadcastSelectedTimerItemChange() {
        Task { @MainActor in
            let item = selectedTimerItem.itemModel(timerInterval: timerDuration)
            self.theme = item.theme
            guard case .withTimer(let timer) = state else {
                self.state = .withTimer(item)
                return
            }
            guard timer != item else { return }
            self.state = .transitioningBetweenReminders
            self.panGestureTranslation = 0
            try? await Task.sleep(for: .milliseconds(0.5))
            withAnimation(.snappy) {
                self.state = .withTimer(item)
            }
        }
    }
}

#warning("Move to VanorUI")
public struct FocusQuickStartView: ConfigurableView {
    
    typealias TimerType = FocusQuickViewModel.TimerType
    
    public struct Model: Hashable {
        let reminders: [ReminderModel]
        let startTimer: (FocusSessionModel) -> Void
        let presentQuickStartView: () -> Void
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(reminders)
        }
        
        public static func ==(lhs: Model, rhs: Model) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
    }
    
    @State private var viewModel: FocusQuickViewModel = .init()
    let model: Model
    
    public init(model: Model) {
        self.model = model
    }
    
    var theme: LCHColor {
        viewModel.selectedTimerItem.theme
    }
    
    public var body: some View {
        
        VStack(alignment: .center, spacing: 0) {
            CarouselSelectorView(selectedItem: viewModel.selectedTimerItem,
                                 items: viewModel.timerItems)
            .fixedSize(horizontal: false, vertical: true)
            .disabled(true)
            
            Group {
                switch viewModel.state {
                case .idle:
                    EmptyView()
                case .withTimer(let model):
                    SelectedTimerInfo(model: model)
                        .popIn(percent: viewModel.panGestureTranslation)
                        .transition(.popIn)
                case .transitioningBetweenReminders:
                    Color.clear
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .contentShape(Rectangle())
        .sensoryFeedback(.selection, trigger: viewModel.selectedTimerItem)
        .gesture(DragPopGesture(isEnabled: true, translation: dragGestureHandler, hasEnded: hasEnded))
        .simultaneousGesture(TapGesture().onEnded(model.presentQuickStartView))
        .safeAreaInset(edge: .top, alignment: .center, spacing: 8) {
            TopView {
                model.presentQuickStartView()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
        .safeAreaInset(edge: .bottom, alignment: .center, spacing: 8) {
            BottomView(timerDuration: viewModel.timerDuration, increment: viewModel.increment, decrement: viewModel.decrement) {
                model.startTimer(viewModel.selectedFocusSessionModel)
            }
        }
        .padding(.init(top: 16, leading: 0, bottom: 16, trailing: 0))
        .background(content: {
            LinearGradient(stops: [
                .init(color: viewModel.theme.surfacePrimary, location: 0),
                    .init(color: viewModel.theme.surfaceSecondary, location: 0.5),
                    .init(color: viewModel.theme.surfaceTertiary, location: 1)
            ], startPoint: .top, endPoint: .bottom)
            .onTapGesture(perform: model.presentQuickStartView)
        })
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .task(id: model.reminders) {
            self.viewModel.timerItems = [.focus] + model.reminders.map { .reminder($0) }
            self.viewModel.updateSelectedReminder(forwards: false, backwards: false)
        }
        .environment(\.theme, theme)
        
    }
    
    
    // MARK: - Gestures
    
    private func dragGestureHandler(_ point: CGPoint) {
        let x = point.x
        guard abs(x) > 0 else {
            withAnimation(.snappy) {
                viewModel.panGestureTranslation = 0
            }
            return
        }
        let diff = min(1, max(0, abs(x)/FocusQuickViewModel.translationsXThreshold))
        viewModel.panGestureTranslation = diff
    }
    
    private func hasEnded(_ point: CGPoint) {
        let x = point.x
        guard abs(x) > FocusQuickViewModel.translationsXThreshold else {
            withAnimation(.snappy) {
                self.viewModel.panGestureTranslation = 0
            }
            return
        }
        viewModel.updateSelectedReminder(forwards: x < 0, backwards: x > 0)
    }
    
    
    // MARK: - Top View
    
    struct TopView: View {
        
        @Environment(\.theme) var theme: LCHColor
        let action: () -> Void
        
        var body: some View {
            HStack(alignment: .center, spacing: 12) {
                Text("Quick Start")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(theme.foregroundPrimary)
                
                Spacer()
                
                Button(action: action) {
                    Image(systemSymbol: .chevronUpForward2)
                        .font(.headline)
                }
                .buttonStyle(CueAccessoryButtonStyle(size: .small, withGlass: true, color: theme.surfacePrimary))
            }
        }
        
    }
    
    // MARK: - Bottom View
    
    struct BottomView: View {
        @Environment(\.theme) var theme
        let timerDuration: TimeInterval
        let increment: () -> Void
        let decrement: () -> Void
        let start: () -> Void
        
        var body: some View {
            VStack(alignment: .center, spacing: 8) {
                TimerIncrementView(timerDuration: timerDuration, increment: increment, decrement: decrement) {
                    // Do Nothing
                }
                
                Button {
                    start()
                } label: {
                    Text("Start")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .tint(theme.baseColor)
                .controlSize(.large)
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Carousel
    
    struct CarouselSelectorView: View {
        
        static let itemSize: CGSize = .init(width: 72, height: 72)
        let selectedItem: FocusQuickViewModel.TimerType?
        let items: [FocusQuickViewModel.TimerType]
        @State private var scrollContainerSize: CGSize = .zero
        
        var body: some View {
            CentralizeItemCarousel(selectedItem: selectedItem, itemSize: Self.itemSize, items: items) { item in
                itemBubbleBuilder(icon: item.icon, theme: item.theme, selected: selectedItem == item)
            }
            .frame(height: Self.itemSize.height)
            .scrollIndicators(.hidden)
        }
        
        @ViewBuilder
        private func itemBubbleBuilder(icon: Icon, theme: LCHColor, selected: Bool) -> some View {
            let backgroundColor: Color = theme.surfaceSecondary/*selected ? Color.proSky.surfaceSecondary : Color.surfaceTertiary*/
            ReminderIconView(icon: icon,
                             foregroundColor: .primary,
                             backgroundColor: backgroundColor,
                             font: .largeTitle)
            .overlay(alignment: .center) {
                if selected {
                    Circle()
                        .fill(Color.clear)
                        .stroke(theme.outlineTertiary, lineWidth: 2)
                }
            }
            .padding(.all, 4)
            .frame(width: Self.itemSize.width, height: Self.itemSize.height, alignment: .center)
        }
    }
    
    // MARK: - SelectedTimerInfo
    
    struct SelectedTimerInfo: View {
        
        struct Model: Identifiable, Hashable {
            let title: String
            let theme: LCHColor
            let timerDuration: TimeInterval
            
            var id: Int { hashValue }
        }
        
        let model: Model
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                Text(model.title)
                    .font(.title2.weight(.semibold))
            }
            .foregroundColor(model.theme.foregroundTertiary)
        }
    }
    
    // MARK: - ConfigurableView
    
    public static var viewName: String { "FocusQuickStartView" }
}


#Preview {
    FocusQuickStartView(model: .init(reminders: [.exampleOne(), .exampleTwo(), .exampleThree(), .exampleFour()],
                                     startTimer: { _ in
        print("(DEBUG) startTimer")
    },
                                     presentQuickStartView: {  print("(DEBUG) fix fix") }))
    .padding(.horizontal, 16)
    .aspectRatio(0.85, contentMode: .fit)
    .frame(maxWidth: .infinity, alignment: .center)
}
