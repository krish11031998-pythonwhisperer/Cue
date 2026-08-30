//
//  CreateFocusSessionShet.swift
//  Cue
//
//  Created by Krishna Venkatramani on 25/08/2026.
//

import Model
import SwiftUI
import VanorUI
import FamilyControls

struct LargeTextPill: ViewModifier {
    
    var value: Double
    
    func body(content: Content) -> some View {
        content
            .font(.title.weight(.bold))
            .contentTransition(.numericText(value: value))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .center)
            .glassEffect(.regular, in: .capsule)
    }
}

extension View {
    func largeTextPill(value: Double) -> some View {
        self.modifier(LargeTextPill(value: value))
    }
}

struct RowLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 8) {
            configuration.icon
                .frame(maxWidth: .infinity, alignment: .leading)
            configuration.title
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .modifier(RowBackground())
        .clipShape(.capsule)
    }
}

struct SmallLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 4) {
            configuration.icon
            configuration.title
        }
    }
}

extension FocusTimerType {
    static func sessionType(_ timerType: FocusSessionKind) -> Self {
        switch timerType {
        case .classic:
            return .classic
        case .pomodoro:
            return .pomodoro
        }
    }
}

@Observable
@MainActor
class CreateFocusSessionViewModel: TimerAdjustmentManager {
    
    enum Presentation: Int, Identifiable, Hashable {
        case appBlock
        
        var id: Int { rawValue }
    }
    
    private static let hourMark: TimeInterval = 60 * 60
    var title: String = "Focus Session"
    var timerDuration: TimeInterval = 30 * 60
    var breakDuration: TimeInterval = 5 * 60
    var sessionCount: Int = 2
    var timerType: FocusTimerType = .classic
    var alarmKind: FocusSessionAlarmOption = .off
    var presentation: Presentation? = nil
    var familySelection: FamilyActivitySelection = .init()
    @ObservationIgnored
    var store: Store?
    
    var step: TimeInterval {
        if timerDuration < Self.hourMark {
            return 5 * 60
        } else {
            return 15 * 60
        }
    }
    
    var focusSessionKind: FocusSessionKind {
        switch timerType {
        case .classic:
            return .classic
        case .pomodoro:
            return .pomodoro
        }
    }
    
    var minBound: TimeInterval {
        5 * 60
    }
    
    var maxBound: TimeInterval {
        24 * Self.hourMark
    }
    
    func incrementBreakDuration() {
        breakDuration += 5 * 60
    }
    
    func decrementBreakDuration() {
        breakDuration -= 5 * 60
    }
    
    func incrementSessionCount() {
        sessionCount += 1
    }
    
    func decrementSessionCount() {
        sessionCount -= 1
    }
    
    func prefillFocusSession(_ focusSessionModel: FocusSessionModel) {
        self.title = focusSessionModel.name
        self.timerDuration = focusSessionModel.timerDuration
        self.breakDuration = focusSessionModel.breakDuration
        if let sessionCount = focusSessionModel.sessionCount {
            self.sessionCount = sessionCount
        }
        self.sessionCount = focusSessionModel.sessionCount ?? 2
        self.timerType = .sessionType(focusSessionModel.sessionType)
        self.alarmKind = focusSessionModel.alarm
        if let blockedApps = focusSessionModel.blockedApps {
            self.familySelection = blockedApps
        }
    }
    
    func createOrUpdateFocusSession(for mode: CreateFocusSessionSheet.Mode) {
        switch mode {
        case .create:
            store?.createFocusSession(name: title,
                                      sessionType: focusSessionKind,
                                      timerDuration: timerDuration,
                                      breakDuration: breakDuration,
                                      blockedApps: familySelection,
                                      alarm: alarmKind,
                                      sessionCount: focusSessionKind == .pomodoro ? sessionCount : nil)
        case .edit(let focusSession):
            store?.updateFocusSession(for: focusSession.objectId) { focusSession in
                focusSession.name = self.title
                focusSession.timerDuration = self.timerDuration
                focusSession.breakDuration = self.breakDuration
                focusSession.alarm = self.alarmKind
                focusSession.blockedApps = self.familySelection
                focusSession.sessionCount = self.sessionCount
            }
        }
    }
}

struct CreateFocusSessionSheet: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(Store.self) var store
    @State private var viewModel: CreateFocusSessionViewModel = .init()
    let mode: Mode
    
    enum Mode: Hashable {
        case create
        case edit(FocusSessionModel)
    }
    
    var theme: LCHColor {
        switch viewModel.timerType {
        case .classic:
            return Color.proSky
        case .pomodoro:
            return Color.proRed
        }
    }
    
    init(mode: Mode) {
        self.mode = mode
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .center, spacing: 0) {
                    // HeaderView
                    
                    SessionImageView()
                    
                    TextField("", text: $viewModel.title)
                        .font(.title2.weight(.semibold))
                        .limitText(textLimit: 30, text: $viewModel.title)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 24)
                
                    Group {
                        if viewModel.timerType == .pomodoro {
                            PomodoroSessionIncrementView(timeManager: viewModel)
                        } else {
                            TimerIncrementView(timerDuration: viewModel.timerDuration, increment: viewModel.increment, decrement: viewModel.decrement)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding(.top, 16)
                    
                    FocusSessionTypeSelector(timerType: $viewModel.timerType)

                    Button {
                        self.viewModel.presentation = .appBlock
                    } label: {
                        AppBlockView(familyActivation: viewModel.familySelection)
                            .modifier(RowBackground())
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .containerShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 16)
                    
                    AlarmSelectionView(timerType: viewModel.timerType, alarmKind: $viewModel.alarmKind)
                        .padding(.top, 16)
                }
            }
            .contentMargins(.horizontal, .init(top: 0, leading: 24, bottom: 0, trailing: 24), for: .scrollContent)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom, alignment: .trailing, spacing: 8, content: {
                HStack(alignment: .center, spacing: 8) {
                    Button {
                       // Delete Focus Session
                    } label: {
                        Image(systemSymbol: .xmark)
                            .font(.title2.weight(.semibold))
                            .tint(theme.foregroundSecondary)
                            .frame(width: 44, height: 44, alignment: .center)
                            .glassEffect(.regular.interactive(true).tint(theme.backgroundSecondary), in: .circle)
                            .contentShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button {
                        viewModel.createOrUpdateFocusSession(for: mode)
                    } label: {
                        Image(systemSymbol: .checkmark)
                            .font(.title2.weight(.semibold))
                            .tint(theme.foregroundSecondary)
                            .frame(width: 44, height: 44, alignment: .center)
                            .glassEffect(.regular.interactive(true).tint(theme.backgroundSecondary), in: .circle)
                            .contentShape(Circle())
                    }
                    
                }
                .padding(.horizontal, 24)
            })
            .background {
                Color.cueItBackground
                    .ignoresSafeArea(edges: .all)
            }
            .sheet(item: $viewModel.presentation) { presentation in
                switch presentation {
                case .appBlock:
                    BlockAppView(selectedActivities: viewModel.familySelection) { selection in
                        viewModel.familySelection = selection
                    }
                }
            }
        }
        .environment(\.theme, theme)
        .task(id: mode) {
            if viewModel.store == nil {
                viewModel.store = store
            }
            
            guard case .edit(let focusSessionModel) = mode else {
                return
            }
            self.viewModel.prefillFocusSession(focusSessionModel)
        }
    }
    
    
    // MARK: - Focus Session type Selector
    
    struct FocusSessionTypeSelector: View {
        
        @Environment(\.theme) var theme
        @Binding var timerType: FocusTimerType
        
        var body: some View {
            Label {
                Menu {
                    ForEach(FocusTimerType.allCases.reversed()) { focusTimerType in
                        Button {
                            // button Action
                            timerType = focusTimerType
                        } label: {
                            Text(focusTimerType.title)
                            Text(focusTimerType.description)
                            Image(systemSymbol: focusTimerType.icon)
                        }
                    }
                } label: {
                    Label(timerType.title, systemSymbol: timerType.icon)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(theme.foregroundPrimary)
                        .padding(.init(top: 8, leading: 10, bottom: 8, trailing: 10))
                        .glassEffect(.regular.tint(theme.backgroundPrimary), in: .capsule)
                }
                .menuStyle(.button)

            } icon: {
                Text("Focus Session Type")
                    .font(.headline)
            }
            .labelStyle(RowLabel())
            .padding(.top, 16)
        }
    }
    
    
    // MARK: - FocusSessionImageView
    
    struct SessionImageView: View {
        
        var body: some View {
            // PlaceHolder for now
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.red)
                .frame(width: 120, height: 120, alignment: .center)
        }
        
    }
    
    
    // MARK: - Timer Increment View
    
    struct TimerIncrementView: View {
        let timerDuration: TimeInterval
        let increment: () -> Void
        let decrement: () -> Void
        
        var body: some View {
            HStack(alignment: .center, spacing: 8) {
                LaunchControlButton(symbol: .same(.minus), isSelected: false, size: .regular, action: decrement)
                Text(timerDuration.longTimerDurationString)
                    .largeTextPill(value: timerDuration)
                    .animation(.easeInOut, value: timerDuration)
                LaunchControlButton(symbol: .same(.plus), isSelected: false, size: .regular, action: increment)
            }
        }
    }
    
    
    // MARK: - Pomodoro Session Increment View
    
    struct PomodoroSessionIncrementView: View {
        
        enum SessionDetail: Hashable, Identifiable {
            case timerDuration(TimeInterval)
            case breakDuration(TimeInterval)
            case sessionCount(Int)
            
            var title: String {
                switch self {
                case .timerDuration:
                    return "Session Duration"
                case .breakDuration:
                    return "Break Duration"
                case .sessionCount:
                    return "Session(s)"
                }
            }
            
            var valueAsString: String {
                switch self {
                case .timerDuration(let timeInterval):
                    return timeInterval.longTimerDurationString
                case .breakDuration(let timeInterval):
                    return timeInterval.longTimerDurationString
                case .sessionCount(let int):
                    return "\(int)"
                }
            }
            
            var animatableValue: Double {
                switch self {
                case .timerDuration(let timeInterval):
                    return timeInterval
                case .breakDuration(let timeInterval):
                    return timeInterval
                case .sessionCount(let int):
                    return Double(int)
                }
            }
            
            var id: String { title }
        }
        
        @Bindable var timeManager: CreateFocusSessionViewModel
        @Namespace var namespace
        private let id: String = "SessionDetailBox"
        @State private var selectionType: SessionDetail? = nil
        

        var sessionDetails: [SessionDetail] {
            [.timerDuration(timeManager.timerDuration), .breakDuration(timeManager.breakDuration), .sessionCount(timeManager.sessionCount)]
        }
        
        var selectionDetailValueAsString: String {
            switch selectionType {
            case .timerDuration:
                return timeManager.timerDuration.longTimerDurationString
            case .breakDuration(let timeInterval):
                return timeManager.breakDuration.longTimerDurationString
            case .sessionCount(let int):
                return "\(timeManager.sessionCount)"
            case nil:
                return ""
            }
        }
        
        var selectionDetailValue: String {
            switch selectionType {
            case .timerDuration:
                return timeManager.timerDuration.longTimerDurationString
            case .breakDuration(let timeInterval):
                return timeManager.breakDuration.longTimerDurationString
            case .sessionCount(let int):
                return "\(timeManager.sessionCount)"
            case nil:
                return ""
            }
        }
        
        var body: some View {
            ZStack(alignment: .center) {
                if selectionType == nil {
                    HStack(alignment: .center, spacing: 8) {
                        ForEach(sessionDetails) { sessionDetail in
                            SessionDetailButton(selectionType: $selectionType, namespace: namespace, sessionDetail: sessionDetail)
                        }
                    }
                }
                
                if let selectionType {
                    HStack(alignment: .center, spacing: 8) {
                        LaunchControlButton(symbol: .same(.minus), isSelected: false, size: .regular, action: {
                            switch selectionType {
                            case .timerDuration:
                                timeManager.decrement()
                            case .breakDuration:
                                timeManager.decrementBreakDuration()
                            case .sessionCount:
                                timeManager.decrementSessionCount()
                            }
                        })
                        .transition(.popIn)
                        
                        Text(selectionDetailValueAsString)
                            .matchedGeometryEffect(id: selectionType.id+"_value",
                                                   in: namespace,
                                                   properties: .position)
                            .largeTextPill(value: selectionType.animatableValue)
                            .matchedGeometryEffect(id: selectionType.id,
                                                   in: namespace,
                                                   properties: .frame,
                                                   anchor: .center)
                            .animation(.easeInOut, value: selectionDetailValue)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                self.selectionType = nil
                            }
                        
                        LaunchControlButton(symbol: .same(.plus), isSelected: false, size: .regular, action: {
                            switch selectionType {
                            case .timerDuration:
                                timeManager.increment()
                            case .breakDuration:
                                timeManager.incrementBreakDuration()
                            case .sessionCount:
                                timeManager.incrementSessionCount()
                            }
                        })
                        .transition(.popIn.animation(.easeInOut.delay(0.3)))
                    }
                }
            }
            .animation(.easeInOut, value: selectionType)
        }
        
        
        // MARK: - SessionDetailButton
        
        struct SessionDetailButton: View {
            
            @Binding var selectionType: SessionDetail?
            let namespace: Namespace.ID
            let sessionDetail: SessionDetail
            
            var body: some View {
                Button {
                    self.selectionType = sessionDetail
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sessionDetail.title)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text(sessionDetail.valueAsString)
                            .font(.headline)
                            .matchedGeometryEffect(id: sessionDetail.id+"_value", in: namespace, properties: .position)
                            .frame(maxHeight: .infinity, alignment: .top)
                    }
                    .padding(.all, 9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassEffect(.regular, in: .roundedRect(cornerRadius: 18))
                    .contentShape(Rectangle())
                    .matchedGeometryEffect(id: sessionDetail.id,
                                           in: namespace,
                                           properties: .frame,
                                           anchor: .center,
                                           isSource: true)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    
    // MARK: - App Block View
    
    struct AppBlockView: View {
        
        let familyActivation: FamilyActivitySelection
        
        enum CategoryType: Identifiable, Equatable {
            case apps(Int)
            case categories(Int)
            case webDomains(Int)
            
            var icon: SFSymbol {
                switch self {
                case .apps:
                    return .appGrid
                case .categories:
                    return .square3Layers3dDownRight
                case .webDomains:
                    return .network
                }
            }
            
            var title: String {
                switch self {
                case .apps:
                    return "Apps"
                case .categories:
                    return "Categories"
                case .webDomains:
                    return "Web Domains"
                }
            }
            
            var count: String {
                switch self {
                case .apps(let count):
                    return "\(count)"
                case .categories(let count):
                    return "\(count)"
                case .webDomains(let count):
                    return "\(count)"
                }
            }
            
            var id: String {
                "\(icon.rawValue)_\(title)"
            }
            
            static func ==(lhs: Self, rhs: Self) -> Bool {
                switch (lhs, rhs) {
                case (.apps(let lhsCount), .apps(let rhsCount)):
                    return lhsCount == rhsCount
                case (.categories(let lhsCount), .categories(let rhsCount)):
                    return lhsCount == rhsCount
                case (.webDomains(let lhsCount), .webDomains(let rhsCount)):
                    return lhsCount == rhsCount
                default:
                    return false
                }
            }
        }
        
        var categoryType: [CategoryType] {
            [
                .apps(familyActivation.applications.count),
                .categories(familyActivation.categories.count),
                .webDomains(familyActivation.webDomains.count)
            ]
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Block Apps")
                    .font(.headline)
                
                HStack(alignment: .center, spacing: 0) {
                    ForEach(categoryType) { category in
                        if category != categoryType.first {
                            Spacer()
                        }
                        VStack(alignment: .center, spacing: 8) {
                            Label(category.title, systemSymbol: category.icon)
                                .font(.caption.weight(.semibold))
                                .labelStyle(SmallLabelStyle())
                            Text(category.count)
                                .font(.headline)
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
    }
    
    
    // MARK: - Alarm Selection View
    
    struct AlarmSelectionView: View {
        
        @Environment(\.theme) var theme
        let timerType: FocusTimerType
        @Binding var alarmKind: FocusSessionAlarmOption
        @State private var alarmOn: Bool = false

        var body: some View {
            Group {
                switch timerType {
                case .classic:
                    Toggle(isOn: $alarmOn) {
                        Text("Alarm")
                            .font(.headline)
                            .tint(theme.baseColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .onChange(of: alarmOn) { oldValue, newValue in
                        alarmKind = alarmOn ? .endOfSession : .off
                    }
                case .pomodoro:
                    HStack(alignment: .center, spacing: 8) {
                        Text("Alarm")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        LaunchControlButton(symbol: .init(base: .alarm, selected: .alarmWavesLeftAndRightFill), isSelected: alarmKind != .off, size: .regular, menu: {
                            Button {
                                alarmKind = .off
                            } label: {
                                Text("Turn Off")
                                Text("No alarms fired")
                                Image(systemSymbol: .xmarkCircle)
                            }
                            
                            Button {
                                alarmKind = .endOfSession
                            } label: {
                                Text("End of Session")
                                Text("Set one alarm that will fire at the end of the final focus session")
                                Image(systemSymbol: .clockBadgeCheckmarkFill)
                            }
                            
                            Button {
                                alarmKind = .betweenSessions
                            } label: {
                                Text("Between Session")
                                Text("Set alarms that will fire at the end of each focus session")
                                Image(systemSymbol: .clock)
                            }
                        })
                    }
                    .environment(\.theme, theme)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .modifier(RowBackground())
            .clipShape(.capsule)
        }
        
    }
}


fileprivate struct TestView: View {
    
    let mode: CreateFocusSessionSheet.Mode
    @State private var presentSheet: Bool = false
    
    var body: some View {
        Button {
            presentSheet = true
        } label: {
            Text("Present Sheet")
                .font(.headline)
                .padding(.all, 12)
        }
        .buttonStyle(.glassProminent)
        .sheet(isPresented: $presentSheet) {
            CreateFocusSessionSheet(mode: mode)
                .presentationDetents([.large])
                .presentationBackground {
                    Color.clear
                }
        }
    }
}


#Preview("Create") {
    TestView(mode: .create)
        .environment(Store())
}

#Preview("Edit (Classic)") {
    TestView(mode: .edit(.init(name: "Deep Focus", sessionType: .classic, timerDuration: 3 * 60 * 60, breakDuration: 15 * 60, blockedApps: nil, alarm: .endOfSession, sessionCount: nil, reminder: nil)))
        .environment(Store())
}


#Preview("Edit (Pomodoro)") {
    TestView(mode: .edit(.init(name: "Let's do this!", sessionType: .pomodoro, timerDuration: 45 * 60, breakDuration: 15 * 60, blockedApps: nil, alarm: .endOfSession, sessionCount: 4, reminder: nil)))
        .environment(Store())
}
