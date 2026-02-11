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
    @State private var viewModel: PaywallViewModel = .init()
//    @State private var selectedProduct: Product = .topProduct
//    @State private var presentProductRoadMap: Bool = false
    
    var showButtonLoading: Bool {
        subscriptionManager.isPurchasing || subscriptionManager.isFetchingOfferings
    }
    
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
                    .padding(.horizontal, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                }
                .padding(.bottom, 64)
                
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
        .background(alignment: .top) {
            RadialGradient(stops: [.init(color: Color.proSky.baseColor, location: 0), .init(color: Color.proSky.baseColor.opacity(0), location: 1)], center: .top, startRadius: 0, endRadius: 300)
                .ignoresSafeArea(edges: .vertical)
        }
        .safeAreaBar(edge: .bottom, alignment: .center, spacing: 8) {
            CueLargeButton {
                if let selectedProduct = viewModel.selectedProduct {
                    Task {
                        let wasSucess = await subscriptionManager.purchase(selectedProduct)
                        if wasSucess {
                            dismiss()
                        }
                    }
                }
            } content: {
                Text("Continue")
                    .font(.headline)
                    .opacity(showButtonLoading ? 0 : 1)
                    .overlay(alignment: .center) {
                        if showButtonLoading {
                            ProgressView()
                        }
                    }
            }
            .disabled(showButtonLoading)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("", systemSymbol: .xmark) {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $viewModel.presentProductRoadMap, content: {
            ProductRoadMap()
        })
        .task {
            await subscriptionManager.fetchOfferings()
            let currentOffering = subscriptionManager.offerings?.current
            viewModel.updateProducts(currentOffering)
        }
    }
    
    
//    private func retrieveProducts(offering: Offering?) async {
//        guard let offering else { return }
//        let packagesWithFreeTrial = await subscriptionManager.checkIfUserIsEligibleForFreeTrial(offering.availablePackages)
//        
//        packagesWithFreeTrial.forEach { (package, freeTrial) in
//            print("""
//                  (DEBUG) 
//                  title: \(package.storeProduct.localizedTitle),
//                  period: \(package.storeProduct.productType)
//                  price: \(package.storeProduct.localizedPriceString),
//                  type: \(package.storeProduct.localizedPricePerMonth),
//                  description: \(package.storeProduct.localizedDescription),
//                  isTrial: \(freeTrial)
//                  trialInfo: \(package.storeProduct.introductoryDiscount)
//                """)
//            
//            if let intro = package.storeProduct.introductoryDiscount {
//                print("""
//                    introDiscount: \(intro.paymentMode),
//                    subscriptionPerios: \(intro.subscriptionPeriod.value) - \(intro.subscriptionPeriod.unit)
//                """)
//            }
//        }
//        
//    }
    
    
    
}


#Preview {
    @Previewable @State var subscriptionManager: SubscriptionManager = .init()
    CuePaywallView()
        .environment(subscriptionManager)
}
