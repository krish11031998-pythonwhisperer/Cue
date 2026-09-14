//
//  AppLink.swift
//  Cue
//
//  Created by Krishna Venkatramani on 13/09/2026.
//

import Foundation

/// Single source of truth for the outward-facing links and identity strings.
enum AppLink {
    
    /// TODO: replace with the real App Store id once the listing is live —
    /// `rateApp` uses the in-app review sheet, but `appStore` is what gets shared.
    static let appStoreID: String = "0000000000"
    
    static let supportEmail: String = "krish_venkat11@hotmail.com"
    
    static var appStore: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)")!
    }
    
    /// Deep-links straight to the "Write a Review" composer on the listing.
    static var writeReview: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!
    }
    
    static let privacyPolicy: URL = .init(string: "https://sparkling-tablecloth-441.notion.site/cue-it-Privacy-Policy-45224c4d70314ccf893c25e919ae836a")!
    
    static let termsOfUse: URL = .init(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
}

enum AppInfo {
    
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
    
    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }
    
    static var versionAndBuild: String {
        #if DEBUG
        "\(version) (\(build))"
        #else
        "\(version)"
        #endif
    }
}
