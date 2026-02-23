//
//  TimerSheet.swift
//  Cue
//
//  Created by Krishna Venkatramani on 12/02/2026.
//

import SwiftUI
import Model
import VanorUI

public struct TimerSheet: View {
    
    let reminderModels: [ReminderModel]
    @State var timeDuration: TimeInterval = 20 * 60
    @State private var selectedReminder: ReminderModel? = nil
    private let startTimer: (ReminderModel?, TimeInterval) -> Void
    
    init(reminderModels: [ReminderModel], startTimer: @escaping (ReminderModel?, TimeInterval) -> Void) {
        self.reminderModels = reminderModels
        self.startTimer = startTimer
    }
    
    var startingProgress: CGFloat {
        20/60
    }
    
    public var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Label("Start Timer", systemSymbol: .timer)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
            
            Text(String.formattedTimelineInterval(timeDuration))
                .font(.title)
                .fontWeight(.semibold)
                .contentTransition(.numericText(value: timeDuration))
                .animation(.easeInOut, value: timeDuration)
                .padding(.bottom, 24)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal) {
                HStack(spacing: 16) {
                    ForEach(reminderModels, id: \.self) { reminder in
                        Button {
                            self.selectedReminder = reminder
                        } label: {
                            ReminderTile(reminder: reminder, isSelected: selectedReminder == reminder)
                        }
                        .frame(minHeight: 72)
                        .buttonStyle(.plain)
                    }
                }
                .scrollTargetLayout() // ✅ tells SwiftUI this stack contains targets
                .padding(.horizontal, 16)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            
            InteractiveSwiftUIView(progress: startingProgress) { progress in
                computeTime(progress: progress)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            
            CueLargeButton {
                startTimer(selectedReminder, timeDuration - (timeDuration.truncatingRemainder(dividingBy: 60)))
            } content:  {
                Text("Start Timer")
                    .font(.headline)
            }

        }
        .padding(.top, 32)
    }
    
    
    // MARK: - Helpers
    
    private func computeTime(progress: CGFloat) {
        let timeInDay: TimeInterval = 60 * 60
        let time = progress * timeInDay
        print("(DEBUG) time: ", time)
        self.timeDuration = time.rounded(.up)
    }
}


public struct ReminderTile: View {
    
    enum Position {
        case first, middle, last
    }
    
    let reminder: ReminderModel
    let isSelected: Bool
    
    init(reminder: ReminderModel, isSelected: Bool) {
        self.reminder = reminder
        self.isSelected = isSelected
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ReminderIconView(icon: .init(reminder.icon)!,
                             foregroundColor: isSelected ? Color.white : Color.proSky.baseColor,
                             backgroundColor: .clear, font: .headline)
            VStack(alignment: .leading, spacing: 8) {
                Text(reminder.title)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                
                if let schedule = reminder.schedule {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemSymbol: .clockFill)
                        Text(schedule.timeScheduled.timeBuilder())
                    }
                    .font(.caption)
                }
            }
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.init(top: 8, leading: 12, bottom: 8, trailing: 12))
//        .containerRelativeFrame(.horizontal, { width, _ in
//            width - 2 * 20
//        })
        .frame(width: 320)
        .background(isSelected ? Color.proSky.baseColor : Color.secondarySystemBackground,
                    in: .roundedRect(cornerRadius: 16))
    }
    
}
