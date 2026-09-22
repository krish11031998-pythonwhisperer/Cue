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
    
    @Environment(SubscriptionManager.self) var subscriptionManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var viewModel: PaywallViewModel = .init()
    var showButtonLoading: Bool {
        subscriptionManager.isPurchasing || subscriptionManager.isFetchingOfferings
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center, spacing: 0) {
                    HeaderView()
                    
                    ProductRoadMapView {
                        viewModel.presentProductRoadMap = true
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 48)
                    
                    Group {
                        if subscriptionManager.isFetchingOfferings {
                            ProgressView()
                                .progressViewStyle(.automatic)
                                .frame(width: 64, height: 64, alignment: .center)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if viewModel.products.isEmpty {
                            ProductsUnavailableView {
                                Task { await loadProducts() }
                            }
                        } else {
                            ForEach(viewModel.products) { product in
                                PayWallProductButton(model: product.viewConfig, isSelected: viewModel.selectedProduct == product.storeProduct) {
                                    self.viewModel.selectedProduct = product.storeProduct
                                }
                                .padding(.bottom, 16)
                            }
                        }
                    }
                    
                    ProductGuidelines()
                        .padding(.bottom, 48)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, 20)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("", systemSymbol: .xmark) {
                        dismiss()
                    }
                }
            }
            .scrollEdgeEffectStyle(.soft, for: .bottom)
            .safeAreaBar(edge: .bottom, alignment: .center, spacing: 8) {
                PaywallFooterView(restoringPurchase: viewModel.restoringPurchase,
                                  showButtonLoading: showButtonLoading,
                                  canPurchase: viewModel.selectedProduct != nil) {
                    viewModel.purchase { storeProduct in
                        await subscriptionManager.purchase(storeProduct)
                    }
                } restorePurchasesAction: {
                    viewModel.restorePurchase {
                        await subscriptionManager.restorePurchase()
                    }
                }
            }
        }
        .background(alignment: .top) {
            ZStack(alignment: .center) {
                Color.cueItBackground
                RadialGradient(stops: [.init(color: Color.proSky.baseColor, location: 0), .init(color: Color.proSky.baseColor.opacity(0), location: 1)], center: .top, startRadius: 0, endRadius: 300)
            }
            .ignoresSafeArea()
        }
        .alert(isPresented: $viewModel.showError, error: viewModel.errorToShow, actions: {
            Button("Ok", role: .confirm) {
                viewModel.errorToShow = nil
                viewModel.showError = false
            }
        })
        .onChange(of: viewModel.mustDismiss, { _, newValue in
            guard newValue == true else { return }
            dismiss()
        })
        .sheet(isPresented: $viewModel.presentProductRoadMap, content: {
            ProductRoadMap()
        })
        .task {
            await loadProducts()
        }
        .onDisappear {
            self.viewModel.purchaseTask?.cancel()
            self.viewModel.restorePurchaseTask?.cancel()
        }
    }


    // MARK: - Loading

    private func loadProducts() async {
        await subscriptionManager.fetchOfferings()
        viewModel.updateProducts(subscriptionManager.offerings?.current)
    }


    // MARK: - Products Unavailable

    private struct ProductsUnavailableView: View {

        let retryAction: () -> Void

        var body: some View {
            VStack(alignment: .center, spacing: 12) {
                Image(systemSymbol: .exclamationmarkTriangle)
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)

                Text("Plans Unavailable")
                    .font(.headline)

                Text("We couldn't load the subscription options. Please check your connection and try again.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Try Again", action: retryAction)
                    .buttonStyle(.glassProminent)
                    .tint(Color.proSky.baseColor)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 24)
        }
    }


    // MARK: - HeaderView
    
    private struct HeaderView: View {
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            Section {
                VStack(alignment: .center, spacing: 12) {
                    Image(systemSymbol: .sparkles)
                        .resizable()
                        .scaledToFit()
                            .symbolEffect(.pulse, options: .repeat(.periodic(10, delay: 10)))
                            .frame(width: 96, height: 96, alignment: .center)
                    
                    Text("Unlock cue:pro")
                        .font(.title)
                }
                .fontWeight(.semibold)
                .foregroundStyle(colorScheme == .light ? Color.proSky.foregroundSecondary : Color.white)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    
    // MARK: - Product Road Map
    
    private struct ProductRoadMapView: View {
        
        var viewRoadPlanAction: () -> Void
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(CueItProFeatures.allCases) { feature in
                        FeatureRow(feature: feature)
                    }
                }
                .padding(.init(top: 20, leading: 18, bottom: 20, trailing: 18))
                .glassEffect(.regular, in: .roundedRect(cornerRadius: 28))
                
                Button(action: viewRoadPlanAction) {
                    Text("And More")
                        .font(.caption)
                }
                .tint(Color.proSky.baseColor)
                .buttonStyle(.glassProminent)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        
        // MARK: Feature Row
        
        private struct FeatureRow: View {
            
            let feature: CueItProFeatures
            
            var body: some View {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemSymbol: feature.symbol)
                        .renderingMode(.template)
                        .font(.headline)
                        .foregroundStyle(feature.tint)
                        .frame(width: 38, height: 38, alignment: .center)
                        .background(feature.theme.surfacePrimary, in: .rect(cornerRadius: 11))
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(feature.title)
                            .font(.headline)
                            .foregroundStyle(feature.theme.foregroundPrimary)
                        Text(feature.message)
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        if let requirement = feature.requirement {
                            Text(requirement)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    // MARK: - GuideLines
    
    private struct ProductGuidelines: View {
        var body: some View {
            VStack(alignment: .center, spacing: 8) {
                Text("For the full length of each subscription period, cue:it Pro unlocks unlimited Focus Sessions with Pomodoro timers and app blocking, alarm-style reminders, cue:ai, and Tags.")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .center, spacing: 4) {
                    ForEach(CueProSubscriptionGuidelines.allCases, id: \.message) { guideline in
                        Text(guideline.message)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }
    
    
}


#Preview {
    @Previewable @State var subscriptionManager: SubscriptionManager = .init()
    CuePaywallView()
        .environment(subscriptionManager)
}
