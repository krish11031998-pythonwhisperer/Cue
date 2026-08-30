//
//  FocusSessionConfigView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 29/08/2026.
//

import VanorUI
import Model
import SwiftUI
import FamilyControls


struct FocusSessionConfigView: View {
    
    @Environment(\.theme) var theme
    @Binding private var appShieldSelection: FamilyActivitySelection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Focus Session")
                .font(.headline)
            
            HStack(alignment: .center, spacing: 8) {
                Group {
                    AppBlockInfoView(font: .bitcountMedium(style: .title3), infoType: .apps(appShieldSelection.applications.count))
                    AppBlockInfoView(font: .bitcountMedium(style: .title3), infoType: .categories(appShieldSelection.categories.count))
                    AppBlockInfoView(font: .bitcountMedium(style: .title3), infoType: .categories(appShieldSelection.webDomains.count))
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
    
}
