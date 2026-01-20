//
//  TodayTabViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 20/01/2026.
//

import Model
import KKit
import VanorUI
import ColorTokensKit
import SwiftUI
import SFSafeSymbols

@Observable
class TodayViewModel {
    
    func sections(for reminders: [Reminder]) -> [DiffableCollectionSection] {
        let cells = reminders.map { reminder in
            DiffableCollectionItem<LogCellView>(.init(title: reminder.title,
                                                      icon: .init(rawValue: reminder.iconName),
                                                      theme: Color.proSky,
                                                      time: reminder.date,
                                                      state: .hasLogged(.init(hasLogged: false)),
                                                      addEmotion: nil,
                                                      deleteLog: nil))
        }
        
        let layout = NSCollectionLayoutSection.singleColumnLayout(width: .fractionalWidth(1.0),
                                                                  height: .estimated(54),
                                                                  insets: .section(.init(top: 16, leading: 20, bottom: 16, trailing: 20)),
                                                                  spacing: 8)
        
        return [.init(0, cells: cells, header: nil, footer: nil, decorationItem: nil, sectionLayout: layout)]
    }
    
}
