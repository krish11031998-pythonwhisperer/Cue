//
//  FocusRootView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 29/08/2026.
//

import VanorUI
import Model
import SwiftUI
import Combine

struct FocusRootView: View {
    
    @Environment(SubscriptionManager.self) var subscriptionManager
    @Bindable var coordinator: FocusSessionCoordinator
    @Environment(Store.self) var store
    @State private var viewModel: FocusRootViewModel = .init()
    
    init(coordinator: FocusSessionCoordinator) {
        self.coordinator = coordinator
    }
    
    var navBarTitle: AttributedString {
        .init("Focus Session", attributes: .init([.font: Font.bitcountRegular(style: .largeTitle)]))
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .center) {
                Color.cueItBackground
                    .ignoresSafeArea(edges: .all)
                if viewModel.sections.isEmpty {
                    ProgressView()
                        .transition(.opacity.animation(.easeOut))
                } else {
                    CollectionView(section: viewModel.sections, completion: nil)
                        .transition(.scale(scale: 0.985).combined(with: .opacity).animation(.easeIn))
                }
            }
            .ignoresSafeArea(edges: .vertical)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("", systemSymbol: .plus) {
                        self.viewModel.createFocusSessionAction()
                    }
                }
            }
            .navigationTitle(Text(navBarTitle))
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $viewModel.presentation, content: { presentation in
            switch presentation {
            case .presentCreateFocusSession:
                CreateFocusSessionSheet(mode: .create)
            case .editFocusSession(let focusSessionModel):
                CreateFocusSessionSheet(mode: .edit(focusSessionModel))
            }
        })
        .fullScreenCover(item: $viewModel.fullScreenPresentation, content: { fullScreenPresentation in
            switch fullScreenPresentation {
            case .startFocusSession(let focusSessionModel):
                FTActiveSessionView(coordinator: coordinator, mode: .startSession(focusSessionModel))
            case .quickStart:
                FTQuickStartView(coordinator: coordinator, reminders: viewModel.reminders)
            }
        })
        .alert(item: $viewModel.alert, content: { alert in
            Alert(title: Text(alert.title).font(.headline),
                  message: Text(alert.description).font(.subheadline), primaryButton: .default(Text("OK")), secondaryButton: .cancel())
        })
        .task {
            self.viewModel.setup(store: store, subscriptionManager: subscriptionManager, coordinator: coordinator)
        }
    }
}

#warning("Move this to VanorUI")
final class FocusSectionHeaderView: UICollectionViewCell, ConfigurableCollectionSupplementaryView {

    struct Model: Hashable {
        let title: String
    }

    func configure(with model: Model) {
        self.contentConfiguration = UIHostingConfiguration {
            Text(model.title)
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .margins(.vertical, .zero)
    }
}
