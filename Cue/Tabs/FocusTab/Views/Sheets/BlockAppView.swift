//
//  BlockAppView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 11/08/2026.
//

import SwiftUI
import FamilyControls
import VanorUI

struct BlockAppView: View {
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @State private var selectedActivities: FamilyActivitySelection
    let doneAction: (FamilyActivitySelection) -> Void
    
    init(selectedActivities: FamilyActivitySelection, doneAction: @escaping (FamilyActivitySelection) -> Void) {
        self._selectedActivities = .init(initialValue: selectedActivities)
        self.doneAction = doneAction
    }
    
    var items: [AppBlockInfoView.InfoType] {
        [.apps(selectedActivities.applications.count), .categories(selectedActivities.categories.count), .webDomains(selectedActivities.webDomains.count)]
    }
    
    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selectedActivities)
                .tint(Color.cueItBackground)
                .navigationTitle("Select apps to block")
                .navigationBarTitleDisplayMode(.inline)
                .ignoresSafeArea(edges: .bottom)
                .background(alignment: .center, content: {
                    switch colorScheme {
                    case .light:
                        Color(uiColor: .secondarySystemBackground).ignoresSafeArea()
                    case .dark:
                        Color.clear.ignoresSafeArea()
                    @unknown default:
                        Color(uiColor: .secondarySystemBackground).ignoresSafeArea()                        
                    }
                })
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemSymbol: .xmark)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .confirm) {
                            doneAction(selectedActivities)
                            dismiss()
                        }
                        .tint(theme.baseColor)
                        .disabled(selectedActivities.isEmpty)
                    }
                }
                .safeAreaBar(edge: .top, alignment: .center, spacing: 8) {
                    HStack(alignment: .center, spacing: 8) {
                        ForEach(items) { item in
                            AppBlockInfoView(infoType: item)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .background(Color.clear, in: .rect)
                    .animation(.easeInOut, value: selectedActivities)
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
        }
    }
    
    
    struct AppBlockInfoView: View {
        
        enum InfoType: Identifiable, Equatable {
            case categories(Int)
            case apps(Int)
            case webDomains(Int)
            
            var symbol: SFSymbol {
                switch self {
                case .apps:
                    return .lockIphone
                case .categories:
                    return .circleGrid3x3
                case .webDomains:
                    return .network
                }
            }
            
            var title: String {
                switch self {
                case .categories:
                    return "Categories"
                case .apps:
                    return "Apps"
                case .webDomains:
                    return "Websites"
                }
            }
            
            var count: Int {
                switch self {
                case .categories(let count):
                    return count
                case .apps(let count):
                    return count
                case .webDomains(let count):
                    return count
                }
            }
            
            var id: String {
                switch self {
                case .categories:
                    return "categories"
                case .apps:
                    return "apps"
                case .webDomains:
                    return "webDomains"
                }
            }
        }
        
        let infoType: InfoType
        
        init(infoType: InfoType) {
            self.infoType = infoType
        }
        
        var body: some View {
            VStack(alignment: .center, spacing: 4) {
                Image(systemSymbol: infoType.symbol)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Text(infoType.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Text("\(infoType.count)")
                    .font(.headline)
                    .contentTransition(.numericText(value: Double(infoType.count)))
                    .animation(.easeInOut, value: infoType.count)
                    .padding(.top, 8)
            }
        }
        
    }
}
