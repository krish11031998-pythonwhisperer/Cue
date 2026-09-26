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
                    TabCollectionViewController(section: viewModel.sections,
                                                additionalContentInsets: .init(top: viewModel.tagChipFrame.height, left: 0, bottom: 0, right: 0),
                                                completion: nil)
                        .ignoresSafeArea(edges: .all)
                }
            }
            .navigationTitle("Manage")
            .toolbarTitleDisplayMode(.inlineLarge)
            .safeAreaInset(edge: .top, alignment: .center, spacing: 8) {
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .center, spacing: 4) {
                        ForEach(viewModel.tagChipModel) { tagChipModel in
                            TagChipView(model: tagChipModel)
                        }
                    }
                    .padding(.init(top: 12, leading: 16, bottom: 4, trailing: 16))
                    .fixedSize(horizontal: false, vertical: true)
                    .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .local) }) { newValue in
                        self.viewModel.tagChipFrame = newValue
                    }
                }
                .scrollIndicators(.hidden)
                .scrollEdgeEffectStyle(.soft, for: .all)
            }
        }
    }
}


#warning("Move this to VanorUI")

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
