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

struct OptionalIgnoreSafeArea: ViewModifier {
    let condition: Bool
    let edges: Edge.Set
    
    func body(content: Content) -> some View {
        if condition {
            content
                .ignoresSafeArea(edges: edges)
        } else {
            content
        }
    }
}

struct FocusRootView: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
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
        NavigationStack {
            ZStack(alignment: .center) {
                Color.cueItBackground
                    .ignoresSafeArea(edges: .all)
                if viewModel.sections.isEmpty {
                    ProgressView()
                        .transition(.opacity.animation(.easeOut))
                } else {
                    MainContent(viewModel: viewModel)
                        .transition(.scale(scale: 0.985).combined(with: .opacity).animation(.easeIn))
                }
            }
            .modifier(OptionalIgnoreSafeArea(condition: horizontalSizeClass == .compact, edges: .vertical))
            .frame(maxWidth: .infinity, alignment: .center)
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
    
    
    // MARK: MainContent
    
    struct MainContent: View {
        
        @Environment(\.horizontalSizeClass) var horizontalSizeClass
        var viewModel: FocusRootViewModel
        
        var body: some View {
            ZStack(alignment: .center) {
                switch horizontalSizeClass {
                case .compact ,.none:
                    CollectionView(section: viewModel.sections, completion: nil)
                case .regular:
                    HStack(alignment: .center, spacing: 0) {
                        FocusQuickStartView(model: viewModel.quickStartConfig)
                            .padding(.init(top: 0, leading: 16, bottom: 0, trailing: 16))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        CollectionView(section: viewModel.sections, completion: nil)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .ignoresSafeArea(edges: .vertical)
                    }
                @unknown default:
                    CollectionView(section: viewModel.sections, completion: nil)
                }
            }
            .onChange(of: (horizontalSizeClass ?? .compact), initial: true) { _, newValue in
                viewModel.reloadOnTraitChange(newValue)
            }
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
