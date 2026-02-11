//
//  ManageSubsription.swift
//  Kyu
//
//  Created by Krishna Venkatramani on 11/02/2026.
//

import SwiftUI
import RevenueCat
import VanorUI

@MainActor
@Observable
class ViewModel {
    
    var currentOffering: Offering?
    var customerInfo: CustomerInfo?
    
    func fetchCurrentOffering(_ currentOfferingFetcher: () async -> Offering?) async {
        guard let offering = await currentOfferingFetcher() else { return }
        self.currentOffering = offering
    }
    
    var currentProductSubscribedTo: SubscriptionInfo? {
        guard let customerInfo else { return nil }
        return customerInfo.subscriptionsByProductIdentifier.first(where: { (_ , info) in
            return info.isActive
        })?.value
    }
}

struct ManageSubsriptionView: View {
    
    @Environment(SubscriptionManager.self) var subscriptionManager
    @State private var viewModel: ViewModel = .init()
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                if let subscriptionInfo = viewModel.currentProductSubscribedTo {
                    SubscriptionInfoView(subscriptionInfo: subscriptionInfo)
                } else if subscriptionManager.isFetchingOfferings {
                    ProgressView()
                } else {
                    ContentUnavailableView("Missing Date", systemSymbol: .xmarkSealFill)
                        .foregroundStyle(Color.proRed.foregroundSecondary)
                }
                
            }
            .padding(.top, 32)
            .padding(.horizontal, 20)
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationTitle("Cue:it Pro")
            .navigationBarTitleDisplayMode(.large)
        }
        .safeAreaBar(edge: .bottom, alignment: .center, spacing: 0, content: {
            CueLargeButton {
                if let managementURL = viewModel.currentProductSubscribedTo?.managementURL {
                    UIApplication.shared.open(managementURL)
                }
            } content: {
                Text("Manage Subscription")
                    .font(.headline)
            }
            .disabled(viewModel.currentProductSubscribedTo == nil)
        })
        .background(alignment: .center) {
            MeshGradient(width: 2, height: 2, points: [
                [0, 0], [1, 0],
                [0, 1], [1, 1]
            ], colors: [Color.proSky.outlinePrimary, Color.proSky.outlineSecondary, Color.proSky.outlineTertiary, Color.proSky.baseColor])
            .ignoresSafeArea(edges: .all)
        }
        .task {
            viewModel.customerInfo = subscriptionManager.customerInfo
            await viewModel.fetchCurrentOffering {
                await subscriptionManager.fetchOfferings()
                return subscriptionManager.offerings?.current
            }
        }
    }
    
    
    // MARK: - SubscriptionInfoView
    
    struct SubscriptionInfoView: View {
        
        let subscriptionInfo: SubscriptionInfo
        var body: some View {
            VStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Your current subscription")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 4)
                        
                        Group {
                            if let displayName = subscriptionInfo.displayName {
                                Text(displayName)
                                    .foregroundStyle(Color.proSky.foregroundSecondary)
                            } else {
                                Text("Subscription Name not avaiable")
                            }
                        }
                        .font(.headline)
                        .padding(.bottom, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if let price = subscriptionInfo.price {
                            Text(price.formatted)
                                .font(.title)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.bottom, 32)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Features you get with Cue:it Pro are:")
                            .font(.footnote)
                            .foregroundStyle(Color.proSky.foregroundSecondary)
                        
                        ForEach(CueItProFeatures.allCases) { feature in
                            VStack(alignment: .leading, spacing: 6) {
                                Label {
                                    Text(feature.title)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                } icon: {
                                    Image(systemSymbol: feature.symbol)
                                        .renderingMode(.template)
                                }
                                .foregroundStyle(feature.theme.foregroundSecondary)
                                .font(.headline)
                                
                                Text(feature.message)
                                    .font(.footnote)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                    
                }
                .padding(.init(top: 16, leading: 20, bottom: 16, trailing: 20))
                .glassEffect(.clear, in: .roundedRect(cornerRadius: 24))
                
            }
            
        }
        
    }
}

#Preview {
    @Previewable @State var subscriptionManager: SubscriptionManager = .init()
    ManageSubsriptionView()
        .environment(subscriptionManager)
}
