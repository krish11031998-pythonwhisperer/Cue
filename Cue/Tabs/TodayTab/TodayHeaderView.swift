//
//  TodayHeaderView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 21/01/2026.
//

import SwiftUI
import VanorUI

struct TodayHeaderView: View {
    
    private let date: Date
    
    init(date: Date) {
        self.date = date
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.headline)
        }
    }
    
    
    private var title: String {
        date.longDaySymbol
    }
    
}
