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
    @State private var selectedActivitiesDidChange: Bool = false
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
                        .disabled(!selectedActivitiesDidChange)
                    }
                }
                .safeAreaBar(edge: .top, alignment: .center, spacing: 8) {
                    HStack(alignment: .center, spacing: 8) {
                        ForEach(items) { item in
                            AppBlockInfoView(font: .bitcountMedium(style: .title2), infoType: item)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .background(Color.clear, in: .rect)
                    .animation(.easeInOut, value: selectedActivities)
                }
                .scrollEdgeEffectStyle(.soft, for: .top)
                .onChange(of: selectedActivities) { oldValue, newValue in
                    self.selectedActivitiesDidChange = true
                }
        }
    }
}
