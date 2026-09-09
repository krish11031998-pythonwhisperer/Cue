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
                if !viewModel.calendarMonths.isEmpty {
                    TabView(selection: $viewModel.currentMonth) {
                        ForEach(viewModel.calendarMonths) { calendarMonth in
                            Tab(value: calendarMonth) {
                                CalendarMonthView(month: calendarMonth) { day in
                                    let id = Path.day(day.date).id
                                    return (id, namespace)
                                } navigationAction: { day in
                                    self.viewModel.path.append(Path.day(day.date))
                                }
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
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
}

#Preview {
    TodayCalendarView()
}
