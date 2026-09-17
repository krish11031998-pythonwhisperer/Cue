//
//  DaySegmentHeaderView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 17/09/2026.
//

import SwiftUI
import VanorUI
import ColorTokensKit
import SFSafeSymbols

/// Header for one of the day's three stretches — morning, afternoon or evening.
///
/// Carries the stretch's own colour and symbol, the hours it covers, how many of
/// its routines are logged, and a chevron for collapsing it. The stretch `now`
/// falls into is lifted with a tinted backing so the page always says where in
/// the day you are.
struct DaySegmentHeaderView: View {

    typealias TimeOfDay = CalendarDayViewModel.TimeOfDay

    let segment: TimeOfDay
    let completedCount: Int
    let totalCount: Int
    let isCurrent: Bool
    let isCollapsed: Bool

    private var theme: LCHColor { segment.color }
    private var isEmpty: Bool { totalCount == 0 }
    private var isComplete: Bool { totalCount > 0 && completedCount == totalCount }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            symbolBadge

            VStack(alignment: .leading, spacing: 1) {
                Text(segment.title.lowercased())
                    .font(isEmpty ? .bitcountRegular(style: .title3) : .bitcountMedium(style: .title3))
                    .foregroundStyle(isEmpty ? Color.secondary : Color.primary)
                Text(segment.hoursTitle)
                    .font(.caption2)
                    .foregroundStyle(Color.secondary)
            }

            Spacer(minLength: 8)

            if isCurrent {
                Text("now")
                    .font(.bitcountMedium(style: .caption2))
                    .foregroundStyle(theme.foregroundPrimary)
                    .padding(.init(top: 3, leading: 8, bottom: 3, trailing: 8))
                    .background(theme.surfacePrimary, in: .capsule)
            }

            if !isEmpty {
                counter
            }

            Image(systemSymbol: .chevronDown)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.secondary)
                .rotationEffect(.degrees(isCollapsed ? -90 : 0))
        }
        .padding(.init(top: 8, leading: 10, bottom: 8, trailing: 14))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if isCurrent {
                Capsule(style: .continuous)
                    .fill(theme.surfaceTertiary)
            }
        }
        .contentShape(.capsule)
        .animation(.snappy, value: isCollapsed)
    }

    // MARK: - Symbol

    private var symbolBadge: some View {
        Image(systemSymbol: segment.symbol)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(isEmpty ? Color.secondary : theme.foregroundPrimary)
            .frame(width: 30, height: 30, alignment: .center)
            .background(isEmpty ? theme.surfaceTertiary : theme.surfacePrimary, in: .circle)
    }

    // MARK: - Counter

    private var counter: some View {
        HStack(alignment: .center, spacing: 4) {
            if isComplete {
                Image(systemSymbol: .checkmark)
                    .font(.system(size: 9, weight: .bold))
            }
            Text("\(completedCount)/\(totalCount)")
                .font(.bitcountRegular(style: .caption2))
                .contentTransition(.numericText(value: Double(completedCount)))
        }
        .foregroundStyle(isComplete ? theme.foregroundPrimary : Color.secondary)
        .padding(.init(top: 3, leading: 8, bottom: 3, trailing: 8))
        .background(isComplete ? theme.surfacePrimary : theme.surfaceTertiary, in: .capsule)
        .animation(.snappy, value: completedCount)
    }
}


// MARK: - Empty placeholder

/// Stand-in row for a stretch of the day with nothing scheduled in it, so an empty
/// morning still reads as part of the day rather than as a gap in the page.
struct DaySegmentEmptyRow: View {

    let segment: CalendarDayViewModel.TimeOfDay

    var body: some View {
        Text("nothing in the cue")
            .font(.bitcountRegular(style: .footnote))
            .foregroundStyle(Color.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.init(top: 14, leading: 20, bottom: 14, trailing: 20))
            .background {
                Capsule(style: .continuous)
                    .strokeBorder(segment.color.surfacePrimary,
                                  style: .init(lineWidth: 1.5, lineCap: .round, dash: [5, 5]))
            }
    }
}
