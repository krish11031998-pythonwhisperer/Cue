//
//  FocusSessionLiveActivity.swift
//  Cue
//
//  Created by Krishna Venkatramani on 08/08/2026.
//

import WidgetKit
import SwiftUI
import ActivityKit
import VanorUI


struct FocusSessionLiveActivity: Widget {
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusSessionLiveActivityAttributes.self) { context in
            FocusSessionLockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    FocusDynamicExpandedView(context: context)
                }
            } compactLeading: {
                FocusSessionIcon(context, viewType: .iconWithProgressMinimal)
            } compactTrailing: {
                FocusSessionCountdownView(context)
                    .font(.footnote)
            } minimal: {
                FocusSessionIcon(context, viewType: .iconWithProgressMinimal)
            }
        }.supplementalActivityFamilies([.small])
    }
    
    
    // MARK: - Child Views
    
    private struct FocusSessionIcon: View {
        
        enum ViewType {
            case icon
            case iconWithProgess
            case iconWithProgressMinimal
        }
        
        let icon: FocusSessionLiveActivityAttributes.Icon
        let theme: LCHColor
        let viewType: ViewType
        let startDate: Date
        let endDate: Date
        @State private var size: CGSize = .zero
        
        init(_ attributes: ActivityViewContext<FocusSessionLiveActivityAttributes>, viewType: ViewType) {
            self.icon = attributes.attributes.icon
            self.theme = .init(hex: attributes.attributes.colorHex)
            self.viewType = viewType
            self.startDate = attributes.attributes.startDate
            self.endDate = attributes.state.endDate
        }
        
        var lineWidth: CGFloat {
            switch viewType {
            case .icon:
                return 4
            case .iconWithProgess:
                return 6
            case .iconWithProgressMinimal:
                return 2
            }
        }

        var padding: CGFloat {
            switch viewType {
            case .icon:
                return 6
            case .iconWithProgess:
                return 12
            case .iconWithProgressMinimal:
                return 6
            }
        }
        
        var showProgressView: Bool {
            switch viewType {
            case .icon:
                return false
            case .iconWithProgess, .iconWithProgressMinimal:
                return true
            }
        }
        
        var body: some View {
            ZStack(alignment: .center) {
                
                theme.backgroundPrimary

                if showProgressView {
                    CircularProgressView(startDate: startDate, endDate: endDate, theme: theme)
                }

                Group {
                    if let symbol = icon.symbol {
                        Image(systemName: symbol)
                            .resizable()
                            .scaledToFit()
                    } else if let emoji = icon.emoji,
                              let image = Image.fromEmoji(emoji, size: size) {
                        image
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image(systemName: "questionmark")
                            .resizable()
                            .scaledToFit()
                    }
                }
                .font(.subheadline)
                .padding(.all, padding)
                .layoutPriority(2)
            }
            .clipShape(Circle())
            .onGeometryChange(for: CGSize.self, of: { $0.size }, action: { self.size = $0 })
        }
    }
    
    
    // MARK: - FocusSessionTimeInfoView
    
    struct FocusSessionInfoView: View {
        let startDate: Date
        let endDate: Date
        
        init(startDate: Date, endDate: Date) {
            self.startDate = startDate
            self.endDate = endDate
        }
        
        init(_ context: ActivityViewContext<FocusSessionLiveActivityAttributes>) {
            self.startDate = context.attributes.startDate
            self.endDate = context.state.endDate
        }
        
        var body: some View {
            HStack(alignment: .center, spacing: 0) {
                Text(startDate.timeBuilder())
                Spacer()
                Text("→")
                Spacer()
                Text(endDate.timeBuilder())
            }
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            
        }
    }
    
    
    // MARK: -  FocusProgressView
    
    private struct FocusProgressView: View {
        
//        struct CustomProgressStyle: ProgressViewStyle {
//            
//            let color: LCHColor
//            
//            func makeBody(configuration: Configuration) -> some View {
//                VStack(alignment: .leading, spacing: 8) {
//                    if let currentValueLabel = configuration.currentValueLabel {
//                        currentValueLabel
//                            .opacity(0.1)
//                    }
////                    ZStack(alignment: .center) {
////                        ProgressViewShape(pct: 1)
////                            .fill(.secondary.quinary)
////                            .layoutPriority(2)
////                        
////                        ProgressViewShape(pct: configuration.fractionCompleted ?? 0)
////                            .fill(color.surfacePrimary)
////                            .layoutPriority(2)
////                    }
//                    ProgressView(startDate: configuration., restTime: <#T##TimeInterval#>, endDate: <#T##Date#>, color: <#T##Color#>)
//                    .frame(height: 20)
//                }
//            }
//        }
        
        let startDate: Date
        let content: FocusSessionLiveActivityAttributes.ContentState
        let color: Color
        
        init(startDate: Date, content: FocusSessionLiveActivityAttributes.ContentState, colorHex: String) {
            self.startDate = startDate
            self.content = content
            self.color = .init(hex: colorHex)
        }
        
        var body: some View {
            VStack(alignment: .center, spacing: 8) {
                // Start → End
                FocusSessionInfoView(startDate: startDate, endDate: content.endDate)
                
//                TimelineView(.animation) { context in
//                    ProgressView(startDate: startDate, restTime: content.restTime, endDate: content.endDate, timeNow: context.date, color: color)
//                }
//                ProgressView(timerInterval: startDate...content.endDate.addingTimeInterval(-content.restTime), countsDown: false)
//                    .progressViewStyle(CustomProgressStyle(color: .init(color: color)))
//                .tint(color.surfacePrimary)
                ProgressView(startDate: startDate, restTime: content.restTime, endDate: content.endDate, color: color)
            }
        }
        
//        
        private struct ProgressView: View {
            let startDate: Date
            let restTime: TimeInterval
            let endDate: Date
            let color: Color
            
            @State var timeNow: Date = .now
            
            init(startDate: Date, restTime: TimeInterval, endDate: Date, color: Color) {
                self.startDate = startDate
                self.restTime = restTime
                self.endDate = endDate
                self.color = color
            }
            
            var durationPct: CGFloat {
                timeNow.progress(start: startDate, end: endDate)
            }
            
            var body: some View {
                ZStack(alignment: .center) {
                    ProgressViewShape(pct: 1)
                        .fill(.secondary.quinary)
                    
                    ProgressViewShape(pct: durationPct)
                        .fill(color)
                }
                .task {
                    Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
                        print("(DEBUG) creating a timer")
                        let timeNow = Date.now
                        guard timeNow < endDate else {
                            timer.invalidate()
                            return
                        }
                        self.timeNow = timeNow
                    }
                    
                }
            }
        }
    }
    
    
    // MARK: - CircularProgressView
    
    struct CircularProgressView: View {
        
        let startDate: Date
        let endDate: Date
        let theme: LCHColor
        
        init(startDate: Date, endDate: Date, theme: LCHColor) {
            self.startDate = startDate
            self.endDate = endDate
            self.theme = theme
        }
        
        func trimToValue(_ timeNow: Date) -> CGFloat {
            timeNow.progress(start: startDate, end: endDate)
        }
        
        var body: some View {
            TimelineView(.animation) { context in
                ZStack(alignment: .center) {
                    FocusCountdownShape(pct: 0, lineWidth: 2)
                        .fill(theme.surfacePrimary)
                    FocusCountdownShape(pct: trimToValue(context.date), lineWidth: 2)
                        .fill(theme.baseColor)
                }
                .rotationEffect(.degrees(-90))
            }
        }
    }
    
    
    // MARK: - FocusSessionLiveActivity
    
    struct FocusSessionLockScreenLiveActivityView: View {
        
        let context: ActivityViewContext<FocusSessionLiveActivityAttributes>
        
        var color: Color {
            .init(hex: context.attributes.colorHex)
        }
        
        var body: some View {
            VStack(alignment: .center, spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    FocusSessionIcon(context, viewType: .icon)
                        .frame(width: 32, height: 32, alignment: .center)
                    Text(context.attributes.sessionName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                FocusProgressView(startDate: context.attributes.startDate, content: context.state, colorHex: context.attributes.colorHex)
            }
            .padding(.all, 24)
            .background {
                LinearGradient(colors: [color.backgroundPrimary, color.backgroundSecondary, color.backgroundTertiary], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        }
    }
    
    
    // MARK: - FocusSessionCountdownView
    
    struct FocusSessionCountdownView: View {
        
        let startDate: Date
        let endDate: Date
        let restTime: TimeInterval
        let sessionName: String
        let theme: LCHColor
        
        init(_ context: ActivityViewContext<FocusSessionLiveActivityAttributes>) {
            self.startDate = context.attributes.startDate
            self.endDate = context.state.endDate
            self.restTime = context.state.restTime
            self.theme = .init(hex: context.attributes.colorHex)
            self.sessionName = context.attributes.sessionName
        }
        
        
        var body: some View {
            TimelineView(.animation) { context in
                Text(context.date.measurementString(startDate: startDate, endDate: endDate, restTime: restTime))
            }
        }
    }
    
    
    // MARK: - FocusDynamicExpandedView
    
    struct FocusDynamicExpandedView: View {
        
        let context: ActivityViewContext<FocusSessionLiveActivityAttributes>
        
        var theme: LCHColor {
            .init(hex: context.attributes.colorHex)
        }
        
        var body: some View {
            HStack(alignment: .center, spacing: 18) {
                FocusSessionIcon(context, viewType: .iconWithProgess)
                    .frame(width: 72, height: 72, alignment: .center)
                
                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.attributes.sessionName)
                            .font(.headline)
                            .foregroundStyle(theme.foregroundSecondary)
                        FocusSessionCountdownView(context)
                            .font(.title)
                            .fontDesign(.monospaced)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        FocusSessionInfoView(context)
                            .fixedSize(horizontal: true, vertical: true)
                            .foregroundStyle(theme.foregroundTertiary)
                    }
                    
                    Button {
                        // Pause
                    } label: {
                        Image(systemSymbol: .pauseFill)
                            .font(.headline)
                            .foregroundStyle(theme.foregroundSecondary)
                            .padding(.all, 4)
                            .frame(width: 48, height: 48, alignment: .center)
                            .background(theme.backgroundSecondary, in: .circle)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
}


#Preview("FocusSessionLiveActivity",
         as: .content,
         using: FocusSessionLiveActivityAttributes.previewableView()) {
    FocusSessionLiveActivity()
} contentStates: {
    FocusSessionLiveActivityAttributes.ContentState(restTime: 0, endDate: Date.now.addingTimeInterval(100 * 60))
}
