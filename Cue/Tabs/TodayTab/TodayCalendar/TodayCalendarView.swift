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
                    .background {
                        Color.cueItBackground                                  
                            .ignoresSafeArea(.all)
                    }
//                    .overlay(alignment: .top) {
//                        CalendarTagsView(tags: viewModel.tags) { tag in
//                            // Do something
//                        }
//                        .padding(.bottom, 8)
//                        .padding(.horizontal, 16)
//                        .padding(.top, calendarGridFrame.maxY)
//                        .animation(.easeInOut, value: calendarGridFrame.maxY)
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                    }
//                    .onPreferenceChange(CalendarMonthGridSizePreferenceKey.self) { frame in
//                        self.calendarGridFrame = frame
//                    }
                    .safeAreaInset(edge: .bottom) {
                        CalendarTagsView(tags: viewModel.tags) { tag in
                            //
                        }
                        .padding(.bottom, 8)
                        .padding(.horizontal, 16)
                    }
                } else {
                    ContentUnavailableView("Loading..", systemSymbol: .calendar, description: nil)
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
        .task {
            self.viewModel.store = store
        }
    }
}

#Preview {
    TodayCalendarView()
}
