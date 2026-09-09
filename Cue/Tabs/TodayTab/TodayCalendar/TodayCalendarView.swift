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
    
    @Environment(Store.self) var store
    @Namespace var namespace
    @Environment(\.colorScheme) var colorScheme
    @State private var viewModel: TodayCalendarViewModel = .init()
    @State private var calendarGridFrame: CGRect = .zero
    
    typealias Path = TodayCalendarViewModel.Path
    
    var body: some View {
        NavigationStack(path: $viewModel.path) {
            Group {
                if !viewModel.calendarMonths.isEmpty {
                    TabView(selection: $viewModel.currentMonth) {
                        ForEach(viewModel.calendarMonths) { calendarMonth in
                            Tab(value: calendarMonth.id) {
                                CalendarMonthView(month: calendarMonth) { day in
                                    let id = Path.day(day.date).id
                                    return (id, namespace)
                                } navigationAction: { day in
                                    self.viewModel.presentDay(day: day)
                                }
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .background {
                        Color.cueItBackground                                  
                            .ignoresSafeArea(.all)
                    }
                    .safeAreaInset(edge: .bottom) {
                        CalendarTagsView(tags: viewModel.tags) { tag in
                            if viewModel.selectedTags.contains(tag) {
                                viewModel.selectedTags.remove(tag)
                            } else {
                                viewModel.selectedTags.insert(tag)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                } else {
                    ContentUnavailableView("Loading..", systemSymbol: .calendar, description: nil)
                }
            }
            .navigationDestination(for: Path.self) { path in
                switch path {
                case .day(let date):
                    TodayTabView(startDate: date)
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
        .sheet(item: $viewModel.presentation, content: { presentation in
            switch presentation {
            case .calendarDetail(let day):
                CalendaryDetailSheetView(calendarDay: day) {
                    // Do nothing for now
                }
                .fittedPresentationDetent()
                .presentationBackground {
                    Color.clear
                }
            }
        })
        .task {
            self.viewModel.store = store
        }
    }
}

#Preview {
    TodayCalendarView()
}
