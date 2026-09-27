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
    @Namespace private var namespace
    
    var body: some View {
        NavigationStack(path: $viewModel.path) {
            ZStack(alignment: .center) {
                Color.cueItBackground
                    .ignoresSafeArea()
                
                if viewModel.sections.isEmpty {
                    ProgressView()
                        .task { @MainActor [weak viewModel] in
                            viewModel?.namespaceID = namespace
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
            .navigationDestination(for: ManageViewModel.Navigation.self, destination: { path in
                switch path {
                case .routineDetail(let routine, let config):
                    RoutineDetailView(routine: routine)
                        .navigationTransition(.zoom(sourceID: config, in: namespace))
                }
            })
            .safeAreaInset(edge: .top, alignment: .center, spacing: 8) {
                TagChips(viewModel: viewModel)
            }
        }
    }
    
    // MARK: TagChip
    
    private struct TagChips: View {
        let viewModel: ManageViewModel
        
        var body: some View {
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
