//
//  TodayCalendarView.swift
//  Kyu
//
//  Created by Krishna Venkatramani on 09/09/2026.
//

import Foundation
import SwiftUI
import VanorUI
import Model

struct TodayCalendarView: View {
    
    @Namespace var namespace
    @Environment(\.colorScheme) var colorScheme
    @State private var viewModel: TodayCalendarViewModel = .init()
    @State private var size: CGSize = .zero
    
    typealias Path = TodayCalendarViewModel.Path
    
    var body: some View {
        NavigationStack(path: $viewModel.path) {
            Group {
                if let currentMonth = viewModel.currentMonth {
                    VStack(alignment: .center, spacing: 0) {
                        Text(Calendar.current.monthSymbols[currentMonth.month - 1])
                            .font(.bitcountRegular(style: .title1))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 32)
                        LazyVGrid(columns: [.init(.adaptive(minimum: max(44, size.width / 7).rounded(.down)),
                                                  spacing: 0,
                                                  alignment: .center)],
                                  alignment: .center,
                                  spacing: 0) {
                            sectionBuilder(section: currentMonth)
                        }
                        .onGeometryChange(for: CGSize.self, of: { $0.size }) { newValue in
                            self.size = newValue
                        }
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .frame(maxHeight: .infinity, alignment: .top)
                    
                } else {
                    ContentUnavailableView("Loading..", systemSymbol: .calendar, description: nil)
                        .task {
                            viewModel.fetchCalendarSection()
                        }
                }
            }
            .navigationDestination(for: Path.self) { path in
                switch path {
                case .day:
                    TodayTabView {
                        
                    }
                    .navigationTransition(.zoom(sourceID: path.id, in: namespace))
                    .navigationBarBackButtonHidden()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.easeInOut) {
                            self.viewModel.fullScreenPresentation = .settings
                        }
                    } label: {
                        Image(systemSymbol: .gearshape)
                            .font(.headline)
                    }
                }
            }
        }
        .fullScreenCover(item: $viewModel.fullScreenPresentation) { fullScreenPresentation in
            switch fullScreenPresentation {
            case .settings:
                SettingView()
            }
        }
    }
    
    // MARK: - SectionBuilder
    
    @ViewBuilder
    func sectionBuilder(section: TodayCalendarViewModel.Section) -> some View {
        Section {
            if section.firstDayInMonth < 7 {
                ForEach(0..<section.firstDayInMonth - 1, id: \.self) { id in
                    EmptyCalendarDayView()
                        .id("\(section)-\(id)")
                }
            }
            ForEach(section.days) { day in
                Button {
                    self.viewModel.path.append(Path.day(day.date))
                } label: {
                    CalendarDayChipView(model: .init(day: day))
                }
                .buttonStyle(.plain)
                .matchedTransitionSource(id: TodayCalendarViewModel.Path.day(day.date).id, in: namespace)
            }
        } header: {
            CalendarWeekdayView()
        }
        .padding(.bottom, 12)
    }

}

#Preview {
    TodayCalendarView()
}
