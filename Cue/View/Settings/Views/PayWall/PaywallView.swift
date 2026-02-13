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
                    Section {
                        VStack(alignment: .center, spacing: 12) {
                            Image(systemSymbol: .sparkles)
                                .resizable()
                                .scaledToFit()
                                    .symbolEffect(.pulse, options: .repeat(.periodic(10, delay: 10)))
                                    .frame(width: 96, height: 96, alignment: .center)
                            
                            Text("Unlock cue:pro")
                                .font(.largeTitle)
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(colorScheme == .light ? Color.proSky.foregroundSecondary : Color.white)
                    }
                    .containerRelativeFrame(.vertical) { height, _ in
                        height * 0.25
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    VStack(alignment: .center, spacing: 12) {
                        ForEach(CueItProFeatures.allCases, id: \.self) { point in
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
                            .padding(.init(top: 16, leading: 18, bottom: 16, trailing: 18))
                            .glassEffect(.regular, in: .roundedRect(cornerRadius: 24))
                        }
                        
                        Button {
                            viewModel.presentProductRoadMap = true
                        } label: {
                            Text("And More")
                                .font(.caption)
                        }
                        .tint(Color.proSky.baseColor)
                        .buttonStyle(.glassProminent)
                        .padding(.top, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                    }
                    .padding(.bottom, 12)
                    
                    VStack(alignment: .center, spacing: 4) {
                        ForEach(CueProSubscriptionGuidelines.allCases, id: \.message) { guideline in
                            Text(guideline.message)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.bottom, 48)
                    
                    if subscriptionManager.isFetchingOfferings {
                        ProgressView()
                            .progressViewStyle(.automatic)
                            .frame(width: 64, height: 64, alignment: .center)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(viewModel.products) { product in
                            PayWallProductButton(model: product.viewConfig, isSelected: viewModel.selectedProduct == product.storeProduct) {
                                self.viewModel.selectedProduct = product.storeProduct
                            }
                            .padding(.bottom, 16)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("", systemSymbol: .xmark) {
                        dismiss()
                    }
                }
            }
            .safeAreaBar(edge: .bottom, alignment: .center, spacing: 8) {
                PaywallFooterView(restoringPurchase: viewModel.restoringPurchase,
                                  showButtonLoading: showButtonLoading) {
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
            RadialGradient(stops: [.init(color: Color.proSky.baseColor, location: 0), .init(color: Color.proSky.baseColor.opacity(0), location: 1)], center: .top, startRadius: 0, endRadius: 300)
                .ignoresSafeArea(edges: .vertical)
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
            await subscriptionManager.fetchOfferings()
            let currentOffering = subscriptionManager.offerings?.current
            viewModel.updateProducts(currentOffering)
        }
        .onDisappear {
            self.viewModel.purchaseTask?.cancel()
            self.viewModel.restorePurchaseTask?.cancel()
        }
    }
}


#Preview {
    @Previewable @State var subscriptionManager: SubscriptionManager = .init()
    CuePaywallView()
        .environment(subscriptionManager)
}
