//
//  SettingsView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 10/02/2026.
//

import VanorUI
import SwiftUI
import Model

struct SettingView: View {
    
    enum SettingSection: String, CaseIterable, Identifiable {
        case settings
        case product
        
        var id: String {
            rawValue
        }
        
        var items: [Item] {
            switch self {
            case .settings:
                return [.haptics, .notifications, .alarms]
            case .product:
                return [.productRoadMap, .feedback]
            }
        }
    }
    
    enum Item: String, Identifiable {
        // User
        case subscription
        
        // Settings
        case haptics
        case notifications
        case alarms
        
        // Product
        case productRoadMap = "Product Roadmap"
        case feedback
        
        
        var icon: SFSymbol {
            switch self {
            case .subscription:
                return .starHexagonFill
            case .haptics:
                return .wave3Up
            case .notifications:
                return .bellFill
            case .alarms:
                return .alarmWavesLeftAndRightFill
            case .productRoadMap:
                return .listClipboard
            case .feedback:
                return .mailFill
            }
        }
        
        var hasSwitch: Bool {
            switch self {
            case .subscription, .productRoadMap, .feedback:
                return false
            case .haptics, .notifications, .alarms:
                return true
            }
        }
        
        var id: String {
            rawValue
        }
        
        func defaultBoolValues(for user: User?) -> Bool {
            switch self {
            case .haptics:
                return user?.hapticsEnabled ?? false
            case .notifications:
                return user?.notificationEnabled ?? false
            case .alarms:
                return user?.alarmEnabled ?? false
            case .subscription, .productRoadMap, .feedback:
                return false
            }
        }
    }
    
    enum Presentation: String, Identifiable {
        case subscription
        case manageSubscription
        case productRoadMap
        
        var id: String {
            rawValue
        }
    }
    
    @Environment(Store.self) var store
    @Environment(SubscriptionManager.self) var subscriptionManager
    @State private var presentation: Presentation?
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button {
                        if subscriptionManager.userIsPro {
                            self.presentation = .manageSubscription
                        } else {
                            self.presentation = .subscription
                        }
                    } label: {
                        CueItProCard(userIsPro: subscriptionManager.userIsPro)
                    }
                }
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
                
                ForEach(SettingSection.allCases) { section in
                    Section {
                        ForEach(section.items) { item in
                            SettingRowCell(item: item, isOn: item.defaultBoolValues(for: store.user)) {
                                rowToggle(item: item)
                            }
                        }
                    } header: {
                        Text(section.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .environment(\.defaultMinListRowHeight, 64)
            .toolbar {
                ToolbarItem(placement: .largeTitle) {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(item: $presentation) { item in
            Group {
                switch item {
                case .manageSubscription:
                    ManageSubsriptionView()
                case .subscription:
                    CuePaywallView()
                case .productRoadMap:
                    ProductRoadMap()
                }
            }
            .presentationDetents([.large])
            .preferredColorScheme(.dark)
        }
    }
    
    
    // MARK: - Helpers
    
    private func rowToggle(item: Item) {
        switch item {
        case .subscription:
            self.presentation = .subscription
        case .alarms:
            print("(DEBUG) user: " ,store.user)
            store.updateAlarmsAccess()
        case .haptics:
            store.updateUser { user in
                user.hapticsEnabled = !user.hapticsEnabled
            }
        case .notifications:
            store.updateNotificationsAccess()
        case .productRoadMap:
            self.presentation = .productRoadMap
        case .feedback:
            openEmailForFeedback()
        }
    }
    
    private func openEmailForFeedback() {
        let email = "krish_venkat11@hotmail.com"
        let subject = "Cue:it Feedback"
        let body = "Hi Cue:it team, "
        
        let urlString =
        "mailto:\(email)?subject=\(subject)&body=\(body)"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    
    // MARK: - Settings Row
    
    private struct SettingRowCell: View {
        let item: Item
        let action: () -> Void
        @State private var isOn: Bool = false
        
        init(item: Item, isOn: Bool = false, action: @escaping () -> Void) {
            self.item = item
            self.action = action
            self._isOn = .init(initialValue: isOn)
        }
        
        var body: some View {
            if item.hasSwitch {
                Toggle(isOn: $isOn) {
                    Label {
                        Text(item.rawValue.capitalized)
                    } icon: {
                        Image(systemSymbol: item.icon)
                            .renderingMode(.template)
                            .foregroundStyle(Color.proSky.baseColor)
                    }
                    .font(.body)
                    .fontWeight(.medium)
                }
                .onChange(of: isOn) { oldValue, newValue in
                    action()
                }
            } else {
                Label {
                    Text(item.rawValue.capitalized)
                } icon: {
                    Image(systemSymbol: item.icon)
                        .renderingMode(.template)
                        .foregroundStyle(Color.proSky.baseColor)
                }
                .font(.body)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .contentShape(Capsule())
                .onTapGesture(perform: action)
            }
        }
    }
    
}


#Preview {
    SettingView()
}
