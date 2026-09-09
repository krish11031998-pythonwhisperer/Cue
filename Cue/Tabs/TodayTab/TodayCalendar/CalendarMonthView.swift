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
    
    @State private var size: CGSize = .zero
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
    
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text(Calendar.current.monthSymbols[month.month - 1])
                .font(.bitcountMedium(style: .title1))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 32)
            LazyVGrid(columns: [.init(.adaptive(minimum: max(44, size.width / 7).rounded(.down)),
                                      spacing: 0,
                                      alignment: .center)],
                      alignment: .center,
                      spacing: 0) {
                sectionBuilder()
            }
            .onGeometryChange(for: CGSize.self, of: { $0.size }) { newValue in
                self.size = newValue
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxHeight: .infinity, alignment: .top)
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
