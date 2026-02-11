//
//  ProductRoadMap.swift
//  Cue
//
//  Created by Krishna Venkatramani on 11/02/2026.
//

import SwiftUI
import VanorUI

struct ProductRoadMap: View {
    
    enum ProductRoadMap: String, CaseIterable, Identifiable {
        case habits
        case widgets
        case sync
        case iPadAndWatch
        
        var id: String {
            rawValue
        }
        
        var title: String {
            switch self {
            case .habits:
                return rawValue.capitalized
            case .widgets:
                return rawValue.capitalized
            case .sync:
                return "iCloud Sync"
            case .iPadAndWatch:
                return "iPad & Watch"
            }
        }
        
        var message: String {
            switch self {
            case .habits:
                "Create and track habits you want to form, Cue:habit will enable you to log your habits & track goals, all packaged to provide deep-insights about the your progress"
            case .widgets:
                "Widgets to help you stay motivated and on track with your goal"
            case .sync:
                "Sync your reminder, goals & habits across all your devices"
            case .iPadAndWatch:
                "Bring this impactful experience to iPad & Apple Watch"
            }
        }
        
        var targettedVersion: String  {
            switch self {
            case .habits:
                return "1.1"
            case .widgets:
                return "1.2"
            case .sync:
                return "1.3"
            case .iPadAndWatch:
                return "1.4"
            }
        }
    }
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Product Road Map")
                        .font(.title)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .containerRelativeFrame(.vertical) { height, _ in
                            height * 0.2
                        }
                    
                    ForEach(ProductRoadMap.allCases) { product in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.title)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.proSky.baseColor)
                            Text("cue:it \(product.targettedVersion)")
                                .font(.caption)
                            
                            Text(product.message)
                                .font(.footnote)
                                .fontWeight(.medium)
                                .padding(.top, 8)
                        }
                        .padding(.bottom, 12)
                    }
                }
                .padding(.horizontal, 20)
            }
            .background(alignment: .top) {
                RadialGradient(stops: [.init(color: Color.proSky.baseColor, location: 0), .init(color: Color.proSky.baseColor.opacity(0), location: 1)], center: .top, startRadius: 0, endRadius: 300)
                    .ignoresSafeArea(edges: .vertical)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("", systemSymbol: .xmark) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProductRoadMap()
}
