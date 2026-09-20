//
//  SettingsView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 10/02/2026.
//

import VanorUI
import SwiftUI
import Model
internal import AlarmKit
import UserNotifications
import StoreKit

struct SettingView: View {
    
    enum SettingSection: String, CaseIterable, Identifiable {
        case preferences
        case product
        case support
        case about
        
        var id: String {
            rawValue
        }
        
        var title: String {
            rawValue.capitalized
        }
        
        var items: [Item] {
            switch self {
            case .preferences:
                return [.haptics, .notifications, .alarms]
            case .product:
                return [.productRoadMap]
            case .support:
                return [.feedback, .rateApp, .shareApp]
            case .about:
                return [.restorePurchases, .privacyPolicy, .terms]
            }
        }
    }
    
    enum Item: String, Identifiable {
        // User
        case subscription
        
        // Preferences
        case haptics
        case notifications
        case alarms
        
        // Product
        case productRoadMap
        
        // Support
        case feedback
        case rateApp
        case shareApp
        
        // About
        case restorePurchases
        case privacyPolicy
        case terms
        
        var id: String {
            rawValue
        }
        
        var title: String {
            switch self {
            case .subscription:     return "Cue:it Pro"
            case .haptics:          return "Haptics"
            case .notifications:    return "Notifications"
            case .alarms:           return "Alarms"
            case .productRoadMap:   return "Product Roadmap"
            case .feedback:         return "Send Feedback"
            case .rateApp:          return "Rate Cue:it"
            case .shareApp:         return "Share Cue:it"
            case .restorePurchases: return "Restore Purchases"
            case .privacyPolicy:    return "Privacy Policy"
            case .terms:            return "Terms of Use"
            }
        }
        
        var subtitle: String? {
            switch self {
            case .haptics:
                return "Feel a tap as you move through your day"
            case .notifications:
                return "Reminders arrive as notifications"
            case .alarms:
                return "Time-critical cues break through silent mode"
            default:
                return nil
            }
        }
        
        var icon: SFSymbol {
            switch self {
            case .subscription:     return .starHexagonFill
            case .haptics:          return .wave3Up
            case .notifications:    return .bellFill
            case .alarms:           return .alarmWavesLeftAndRightFill
            case .productRoadMap:   return .listClipboard
            case .feedback:         return .mailFill
            case .rateApp:          return .starFill
            case .shareApp:         return .squareAndArrowUp
            case .restorePurchases: return .arrowClockwiseCircleFill
            case .privacyPolicy:    return .lockShieldFill
            case .terms:            return .docTextFill
            }
        }
        
        var tint: Color {
            switch self {
            case .subscription:     return Color.proSky.baseColor
            case .haptics:          return Color.proViolet.baseColor
            case .notifications:    return Color.proSky.baseColor
            case .alarms:           return Color.proTomato.baseColor
            case .productRoadMap:   return Color.proTeal.baseColor
            case .feedback:         return Color.proIndigo.baseColor
            case .rateApp:          return Color.proGold.baseColor
            case .shareApp:         return Color.proGrass.baseColor
            case .restorePurchases: return Color.proMint.baseColor
            case .privacyPolicy:    return Color.proGray.baseColor
            case .terms:            return Color.proGray.baseColor
            }
        }
        
        var hasSwitch: Bool {
            switch self {
            case .haptics, .notifications, .alarms:
                return true
            default:
                return false
            }
        }
        
        /// Rows that hand off to Safari / Mail / the share sheet get the outward accessory.
        var leavesTheApp: Bool {
            switch self {
            case .feedback, .rateApp, .shareApp, .privacyPolicy, .terms:
                return true
            default:
                return false
            }
        }
        
        func defaultBoolValues(for user: UserModel?) -> Bool {
            switch self {
            case .haptics:
                return user?.hapticsEnabled ?? false
            case .notifications:
                return user?.notificationEnabled ?? false
            case .alarms:
                return user?.alarmEnabled ?? false
            default:
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
    
    enum AlertState: String, Identifiable {
        case restoreSucceeded
        case restoreFoundNothing
        case restoreFailed
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .restoreSucceeded:    return "Purchases Restored"
            case .restoreFoundNothing: return "Nothing to Restore"
            case .restoreFailed:       return "Restore Failed"
            }
        }
        
        var message: String {
            switch self {
            case .restoreSucceeded:
                return "Cue:it Pro is active on this device."
            case .restoreFoundNothing:
                return "We couldn't find an active subscription for this Apple Account."
            case .restoreFailed:
                return "Something went wrong. Please check your connection and try again."
            }
        }
    }
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(Store.self) var store
    @Environment(SubscriptionManager.self) var subscriptionManager
    @State private var presentation: Presentation?
    @State private var alertState: AlertState?
    @State private var isRestoring: Bool = false
    @State private var notificationsDenied: Bool = false
    @State private var alarmsDenied: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        playSelectionHaptic()
                        if subscriptionManager.userIsPro {
                            self.presentation = .manageSubscription
                        } else {
                            self.presentation = .subscription
                        }
                    } label: {
                        CueItProCard(userIsPro: subscriptionManager.userIsPro)
                    }
                    .buttonStyle(.plain)
                }
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
                
                ForEach(SettingSection.allCases) { section in
                    Section {
                        ForEach(section.items) { item in
                            if item == .shareApp {
                                ShareLink(item: AppLink.appStore,
                                          subject: Text("Cue:it"),
                                          message: Text("Reminders that actually land.")) {
                                    SettingRowContent(item: item, isBusy: false)
                                }
                                .buttonStyle(.plain)
                            } else {
                                SettingRowCell(item: item,
                                               isOn: item.defaultBoolValues(for: store.userModel),
                                               isBusy: item == .restorePurchases && isRestoring) {
                                    rowToggle(item: item)
                                }
                            }
                        }
                    } header: {
                        Text(section.title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } footer: {
                        sectionFooter(for: section)
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
                
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .close) {
                        self.dismiss()
                    }
                }
            }
        }
        .task {
            await refreshPermissionStatus()
        }
        .onChange(of: scenePhase) { _, newValue in
            guard newValue == .active else { return }
            Task { await refreshPermissionStatus() }
        }
        .alert(item: $alertState) { state in
            Alert(title: Text(state.title),
                  message: Text(state.message),
                  dismissButton: .default(Text("OK")))
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
        }
    }
    
    
    // MARK: - Section Footer
    
    @ViewBuilder
    private func sectionFooter(for section: SettingSection) -> some View {
        if section == .about {
            VersionFooter()
        } else if section == .preferences, notificationsDenied || alarmsDenied {
            VStack(alignment: .leading, spacing: 8) {
                Text(permissionFooterMessage)
                Button("Open iOS Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
                .font(.footnote.weight(.semibold))
                .buttonStyle(.plain)
                .foregroundStyle(Color.proSky.baseColor)
            }
            .font(.footnote)
            .padding(.top, 4)
        }
    }
    
    private var permissionFooterMessage: String {
        switch (notificationsDenied, alarmsDenied) {
        case (true, true):
            return "Notifications and alarms are turned off for Cue:it in iOS Settings, so your cues can't reach you."
        case (true, false):
            return "Notifications are turned off for Cue:it in iOS Settings, so your cues can't reach you."
        default:
            return "Alarms are turned off for Cue:it in iOS Settings, so time-critical cues can't break through."
        }
    }
    
    
    // MARK: - Helpers
    
    private func rowToggle(item: Item) {
        playSelectionHaptic()
        switch item {
        case .subscription:
            self.presentation = .subscription
        case .alarms:
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
        case .rateApp:
            UIApplication.shared.open(AppLink.writeReview)
        case .restorePurchases:
            restorePurchases()
        case .privacyPolicy:
            UIApplication.shared.open(AppLink.privacyPolicy)
        case .terms:
            UIApplication.shared.open(AppLink.termsOfUse)
        case .shareApp:
            // Handled by the `ShareLink` the row is built from — it needs a View, not an action.
            break
        }
    }
    
    private func playSelectionHaptic() {
        guard store.userModel?.hapticsEnabled == true else { return }
        SensoryFeedbackManager.shared.playSelection()
    }
    
    private func refreshPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.notificationsDenied = settings.authorizationStatus == .denied
        self.alarmsDenied = store.alarmManager.authorizationState == .denied
    }
    
    private func restorePurchases() {
        guard !isRestoring else { return }
        isRestoring = true
        Task {
            let result = await subscriptionManager.restorePurchase()
            isRestoring = false
            switch result {
            case .success(true):
                alertState = .restoreSucceeded
            case .success(false):
                alertState = .restoreFoundNothing
            case .failure:
                alertState = .restoreFailed
            }
        }
    }
    
    private func openEmailForFeedback() {
        let subject = "Cue:it Feedback"
        let body = """
        
        
        ———
        Version \(AppInfo.versionAndBuild) · iOS \(UIDevice.current.systemVersion) · \(UIDevice.current.model)
        """
        
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = AppLink.supportEmail
        components.queryItems = [
            .init(name: "subject", value: subject),
            .init(name: "body", value: body)
        ]
        
        guard let url = components.url else { return }
        UIApplication.shared.open(url)
    }
    
    
    // MARK: - Settings Row
    
    private struct SettingRowCell: View {
        let item: Item
        let isOn: Bool
        let isBusy: Bool
        let action: () -> Void
        
        init(item: Item, isOn: Bool = false, isBusy: Bool = false, action: @escaping () -> Void) {
            self.item = item
            self.isOn = isOn
            self.isBusy = isBusy
            self.action = action
        }
        
        var body: some View {
            if item.hasSwitch {
                Toggle(isOn: .init(get: { isOn }, set: { _ in action() })) {
                    SettingRowLabel(item: item)
                }
                .tint(Color.proSky.baseColor)
            } else {
                Button(action: action) {
                    SettingRowContent(item: item, isBusy: isBusy)
                }
                .buttonStyle(.plain)
                .disabled(isBusy)
            }
        }
    }
    
    
    // MARK: - Settings Row Content
    
    private struct SettingRowContent: View {
        let item: Item
        let isBusy: Bool
        
        var body: some View {
            HStack(alignment: .center, spacing: 12) {
                SettingRowLabel(item: item)
                Spacer(minLength: 8)
                if isBusy {
                    ProgressView()
                } else {
                    Image(systemSymbol: item.leavesTheApp ? .arrowUpRight : .chevronRight)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
        }
    }
    
    
    // MARK: - Settings Row Label
    
    private struct SettingRowLabel: View {
        let item: Item
        
        var body: some View {
            HStack(alignment: .center, spacing: 12) {
                Image(systemSymbol: item.icon)
                    .renderingMode(.template)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(item.tint)
                    .frame(width: 28, height: 28)
                    .background(item.tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    
    // MARK: - Version Footer
    
    private struct VersionFooter: View {
        var body: some View {
            VStack(alignment: .center, spacing: 2) {
                Text("Cue:it \(AppInfo.versionAndBuild)")
                Text("Made for the days that don't cooperate.")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 16)
        }
    }
    
}


#Preview {
    SettingView()
        .environment(Store())
        .environment(SubscriptionManager())
}
