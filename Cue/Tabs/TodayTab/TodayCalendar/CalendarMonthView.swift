//
//  CalendarMonthView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/09/2026.
//

import SwiftUI
import Model
import VanorUI

struct CalendarMonthView: View {
    
    @State private var frame: CGRect = .zero
    let month: CalendarMonth
    var transitionIDProvider: (CalendarDay) -> (String, Namespace.ID)
    var navigationAction: (CalendarDay) -> Void
    
    init(month: CalendarMonth,
         transitionIDProvider: @escaping (CalendarDay) -> (String, Namespace.ID),
         navigationAction: @escaping (CalendarDay) -> Void) {
        self.month = month
        self.transitionIDProvider = transitionIDProvider
        self.navigationAction = navigationAction
    }
    
    var size: CGSize {
        frame.size
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text(Calendar.current.monthSymbols[month.month - 1])
                .font(.bitcountMedium(style: .title1))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 32)
            if month.days.isEmpty {
                EmptyView()
            } else {
                LazyVGrid(columns: [.init(.adaptive(minimum: max(44, size.width / 7).rounded(.down)),
                                          spacing: 0,
                                          alignment: .center)],
                          alignment: .center,
                          spacing: 0) {
                    sectionBuilder()
                }
                .onGeometryChange(for: CGRect.self, of: {
                    let frame = $0.frame(in: .named("content"))
                    let safeAreaInset = $0.safeAreaInsets
                    
                    return .init(x: frame.minX, y: frame.minY - safeAreaInset.top, width: frame.width, height: frame.height)
                }) { newValue in
                    self.frame = newValue
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .coordinateSpace(.named("content"))
    }
    
    // MARK: - SectionBuilder
    
    @ViewBuilder
    func sectionBuilder() -> some View {
        Section {
            if month.firstDayInMonth < 7 {
                ForEach(0..<(month.firstDayInMonth - 1), id: \.self) { id in
                    EmptyCalendarDayView()
                        .id("\(month)-\(id)")
                }
            }
            ForEach(month.days) { day in
                let (id, namespace) = transitionIDProvider(day)
                Button {
                    navigationAction(day)
                } label: {
                    CalendarDayChipView(model: .init(day: day))
                }
                .buttonStyle(.plain)
                .matchedTransitionSource(id: id, in: namespace)
            }
        } header: {
            CalendarWeekdayView()
        }
        .padding(.bottom, 12)
    }
}
