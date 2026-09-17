//
//  DayProgressHeaderView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 17/09/2026.
//

import SwiftUI
import VanorUI
import ColorTokensKit

/// Header for a single day in the Today tab.
///
/// Shows the weekday, its date and a rail that reads the day as three coloured
/// stretches — morning, afternoon and evening — filled up to the current moment.
/// The rail doubles as the page's time indicator: on today it carries a marker at
/// `now`, on other days it simply reads as fully spent or completely untouched.
struct DayProgressHeaderView: View {

    typealias TimeOfDay = CalendarDayViewModel.TimeOfDay

    let date: Date
    let now: Date
    let completedCount: Int
    let totalCount: Int

    private static let barHeight: CGFloat = 10
    private static let barSpacing: CGFloat = 4
    private static let markerSize: CGFloat = 12

    private var isToday: Bool { date.startOfDay == now.startOfDay }
    private var isPast: Bool { date.startOfDay < now.startOfDay }

    /// Hours elapsed in the day being shown. Past days read as spent, future days as untouched.
    private var elapsedHours: CGFloat {
        guard isToday else { return isPast ? 24 : 0 }
        return CGFloat(now.hours) + CGFloat(now.minutes) / 60
    }

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            VStack(alignment: .center, spacing: 4) {
                Text(Calendar.current.weekdaySymbols[date.weekDayValue - 1].lowercased())
                    .font(.bitcountMedium(style: .extraLargeTitle))
                Text(date.headerDateStringFormatter())
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .leading, spacing: 6) {
                captionRow
                rail
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Caption

    private var captionRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if isToday {
                HStack(alignment: .center, spacing: 5) {
                    Circle()
                        .fill(TimeOfDay.current(at: now).color.baseColor)
                        .frame(width: 6, height: 6)
                    Text(now.timeBuilder())
                        .font(.bitcountMedium(style: .caption1))
                }
            }

            Spacer(minLength: 0)

            if totalCount > 0 {
                Text("\(completedCount)/\(totalCount) done")
                    .font(.bitcountRegular(style: .caption1))
                    .foregroundStyle(Color.secondary)
                    .contentTransition(.numericText(value: Double(completedCount)))
                    .animation(.snappy, value: completedCount)
            }
        }
    }

    // MARK: - Rail

    private var rail: some View {
        GeometryReader { proxy in
            let spacing = Self.barSpacing * CGFloat(TimeOfDay.allCases.count - 1)
            let usable = max(proxy.size.width - spacing, 0)

            HStack(alignment: .center, spacing: Self.barSpacing) {
                ForEach(TimeOfDay.allCases, id: \.self) { segment in
                    segmentBar(segment, width: usable * segment.dayFraction)
                }
            }
            .frame(width: proxy.size.width, height: Self.barHeight, alignment: .leading)
        }
        .frame(height: Self.barHeight)
    }

    private func segmentBar(_ segment: TimeOfDay, width: CGFloat) -> some View {
        let fill = spentFraction(of: segment)

        return Capsule()
            .fill(segment.color.surfacePrimary)
            .frame(width: width, height: Self.barHeight)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(segment.color.baseColor)
                    .frame(width: width * fill)
            }
            .overlay(alignment: .leading) {
                if isToday, segment.contains(hour: now.hours) {
                    Circle()
                        .fill(Color.cueItBackground)
                        .overlay {
                            Circle()
                                .strokeBorder(segment.color.baseColor, lineWidth: 2.5)
                        }
                        .frame(width: Self.markerSize, height: Self.markerSize)
                        .offset(x: (width * fill) - Self.markerSize / 2)
                }
            }
            .animation(.easeInOut, value: fill)
    }

    /// How much of `segment` has already gone by, 0...1.
    private func spentFraction(of segment: TimeOfDay) -> CGFloat {
        let start = CGFloat(segment.hourRange.lowerBound)
        let end = CGFloat(segment.hourRange.upperBound)
        guard end > start else { return 0 }
        return min(max((elapsedHours - start) / (end - start), 0), 1)
    }
}
