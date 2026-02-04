//
//  CalendarView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 03/02/2026.
//

import SwiftUI
import VanorUI
import Model

struct CalendarView: View {
    
    @Environment(Store.self) var store
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var size: CGSize = .zero
    @State private var viewModel: CalendarViewModel = .init()
    
    var chipBackgroundColor: Color {
        switch colorScheme {
        case .light:
            Color.backgroundSecondary
        case .dark:
            Color.invertedBackgroundSecondary
        @unknown default:
            Color.backgroundSecondary
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                LazyVGrid(columns: [.init(.adaptive(minimum: max(44, size.width / 7).rounded(.down)),
                                          spacing: 0,
                                          alignment: .center)],
                          alignment: .center,
                          spacing: 8) {
                    ForEach(viewModel.calendarData) { section in
                        Section {
                            ForEach(section.days) { day in
                                CalendarChips(config: .init(date: day.date, baseColor: chipBackgroundColor)) {
                                    Group {
                                        if let bubble = viewModel.buildBubbleConfig(for: day) {
                                            ReminderBubbleView(element: bubble, withGlass: false)
                                        } else {
                                            Color.clear
                                        }
                                    }
                                    .aspectRatio(1, contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(.horizontal, 2)
                            }
                        } header: {
                            Text(Calendar.current.monthSymbols[section.month - 1])
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.bottom, 12)
                    }
                }
                          .onGeometryChange(for: CGSize.self, of: { $0.size }) { newValue in
                              print("(DEBUG) width from geometry change: ", newValue.width)
                              self.size = newValue
                          }
                          .padding(.horizontal, 20)
                          .frame(maxWidth: .infinity, alignment: .center)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("", systemSymbol: .xmark) {
                        dismiss()
                    }
                }
            }
        }
        .task {
            viewModel.fetchCalendarSection()
        }
    }
}
