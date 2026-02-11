//
//  PaywallView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 10/02/2026.
//

import SwiftUI
import VanorUI
import RevenueCat

struct CuePaywallView: View {
    
    enum SalesPoint: Int, CaseIterable {
        case focusTimer
        case tags
        case unlimitedReminders
        
        var symbol: SFSymbol {
            switch self {
            case .focusTimer:
                return .stopwatch
            case .tags:
                return .tagFill
            case .unlimitedReminders:
                return .bellFill
            }
        }
        
        var title: String {
            switch self {
            case .focusTimer:
                return "Focus Timer"
            case .tags:
                return "Tags"
            case .unlimitedReminders:
                return "Flexible Reminders"
            }
        }
        
        var message: String {
            switch self {
            case .focusTimer:
                return "Finish tasks without distractions"
            case .tags:
                return "Build routines and stay consistent"
            case .unlimitedReminders:
                return "Never miss a task again"
            }
        }
        
        var tint: Color {
            let theme: LCHColor
            switch self {
            case .focusTimer:
                theme = Color.proRed
            case .tags:
                theme = Color.proBlue
            case .unlimitedReminders:
                theme = Color.proCyan
            }
            
            return theme.baseColor
        }
    }
    
    enum Product {
        case topProduct
        case bottomProduct
    }
    
    @Environment(SubscriptionManager.self) var subscriptionManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedProduct: Product = .topProduct
    @State private var presentProductRoadMap: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 0) {
                Section {
                    Text("Unlock Cue:it Pro")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.white)
                }
                .containerRelativeFrame(.vertical) { height, _ in
                    height * 0.2
                }
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity, alignment: .center)
                
                VStack(alignment: .center, spacing: 12) {
                    ForEach(SalesPoint.allCases, id: \.self) { point in
                        VStack(alignment: .leading, spacing: 6) {
                            Label {
                                Text(point.title)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } icon: {
                                Image(systemSymbol: point.symbol)
                                    .renderingMode(.template)
                                    .foregroundStyle(point.tint)
                            }
                            .font(.headline)
                            
                            Text(point.message)
                                .font(.footnote)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.init(top: 4, leading: 24, bottom: 4, trailing: 24))
                    
                    Button {
                        presentProductRoadMap = true
                    } label: {
                        Text("And More")
                            .font(.caption)
                    }
                    .tint(Color.proSky.baseColor)
                    .buttonStyle(.glassProminent)
                    .padding(.top, 8)
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                }
                .padding(.bottom, 64)
                
                PayWallProductButton(productName: "Yearly", price: 39.99, isSelected: selectedProduct == .topProduct, isYearlyProduct: true, hasTrial: true) {
                    self.selectedProduct = .topProduct
                }
                .padding(.bottom, 16)
                
                PayWallProductButton(productName: "Monthly", price: 4.99, isSelected: selectedProduct == .bottomProduct, isYearlyProduct: false, hasTrial: false) {
                    self.selectedProduct = .bottomProduct
                }
                .padding(.bottom, 16)
                
                
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(alignment: .top) {
            RadialGradient(stops: [.init(color: Color.proSky.baseColor, location: 0), .init(color: Color.proSky.baseColor.opacity(0), location: 1)], center: .top, startRadius: 0, endRadius: 300)
                .ignoresSafeArea(edges: .vertical)
        }
        .safeAreaBar(edge: .bottom, alignment: .center, spacing: 8) {
            Button {
                print("(DEBUG) Continue")
            } label: {
                Text("Continue")
                    .font(.headline)
                    .padding(.init(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .tint(Color.proSky.baseColor)
            .buttonStyle(.glassProminent)
            .padding(.horizontal, 20)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("", systemSymbol: .xmark) {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $presentProductRoadMap, content: {
            ProductRoadMap()
        })
        .task {
            await subscriptionManager.fetchOfferings()
            print("(DEBUG) current Offering: ", subscriptionManager.offerings?.current)
        }
    }
    
}


#Preview {
    CuePaywallView()
}
