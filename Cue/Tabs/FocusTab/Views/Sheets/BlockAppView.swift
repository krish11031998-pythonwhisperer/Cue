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
    
    @Environment(\.dismiss) var dismiss
    @Binding private var selectedActivities: FamilyActivitySelection
    
    init(selectedActivities: Binding<FamilyActivitySelection>) {
        self._selectedActivities = selectedActivities
    }
    
    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selectedActivities)
                .ignoresSafeArea(edges: .vertical)
                .navigationTitle("Select apps to block")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemSymbol: .xmark)
                        }
                    }
                }
        }
    }
    
}
