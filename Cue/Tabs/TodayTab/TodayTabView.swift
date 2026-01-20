//
//  TodayTabView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 19/01/2026.
//

import Foundation
import SwiftUI
import Model
import VanorUI
import SFSafeSymbols
import ColorTokensKit
import KKit

struct TodayTabView: View {
    
    enum Presentation: Int, Identifiable {
        case addReminder = 0
        
        var id: Int { rawValue }
    }
    
    let store: Store
    @State private var presentation: Presentation? = nil
    @State private var viewModel: TodayViewModel = .init()
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .center) {
                if store.reminders.isEmpty {
                    ContentUnavailableView("No Reminders", systemImage: "bell.fill", description: descriptionText)
                        .font(.headline)
                } else {
                    CollectionView(section: viewModel.sections(for: store.reminders),
                                   completion: nil)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.presentation = .addReminder
                    } label: {
                        Image(systemSymbol: .plus)
                            .font(.body)
                    }

                }
            }
        }
        .sheet(item: $presentation) { presentation in
            switch presentation {
            case .addReminder:
                CreateReminderView(store: store)
                    .presentationDetents([.fraction(1)])
            }
        }
    }
    
    
    // MARK: - DescriptionText
    
    private var descriptionText: Text {
        Text("Add Reminders to start organizing your day.")
            .font(.caption)
            .foregroundColor(.foregroundSecondary)
    }
    
}
