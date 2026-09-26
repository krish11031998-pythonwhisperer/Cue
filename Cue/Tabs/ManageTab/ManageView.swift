//
//  ManageView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 25/09/2026.
//

import SwiftUI
import VanorUI
import Model

struct ManageView: View {
    
    @Environment(Store.self) var store
    @State private var viewModel: ManageViewModel = .init()
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .center) {
                if viewModel.sections.isEmpty {
                    ProgressView()
                        .task { @MainActor [weak viewModel] in
                            viewModel?.store = self.store
                        }
                } else {
                    CollectionView(section: viewModel.sections, completion: nil)
                }
            }
            .ignoresSafeArea(edges: .all)
            .navigationTitle("Manage")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}


#Preview {
    let reminder = ReminderModel.exampleFour()
    let routineDays = Array(repeating: 0, count: 30).enumerated().map { element in
        let index = element.offset
        
        let timeInterval = Double(30 - index) * 24 * 60 * 60
        let date = Date.now.addingTimeInterval(-timeInterval)
        return RoutineTimelineCard.RoutineDay(date: date, isLogged: .random())
    }
    let attributedTitle = AttributedString(reminder.title, attributes: .init([.font: Font.bitcountRegular(style: .body)]))
    
    RoutineTimelineCard(model: .init(config: .init(icon: .init(reminder.icon)!, title: attributedTitle, days: routineDays, color: reminder.color), action: nil))
        .containerRelativeFrame(.horizontal) { width, _ in
            width * 0.5
        }
        .frame(maxWidth: .infinity, alignment: .center)
}
