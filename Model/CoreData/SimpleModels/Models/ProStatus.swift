//
//  ProStatus.swift
//  Model
//
//  Created by Krishna Venkatramani on 14/09/2026.
//

import Foundation

/// Whether the user is entitled to Cue:it Pro.
///
/// `unknown` is the important case: it means this device has never had an answer from the
/// store, which is not the same as knowing the user is on the free tier. Without it a cold
/// launch cannot tell "not pro" from "not asked yet", and every pro surface flashes its
/// free-tier state until RevenueCat answers.
public enum ProStatus: Int32, Sendable, Hashable, CaseIterable {
    case unknown = 0
    case free = 1
    case pro = 2
}

/// The persisted snapshot of the last entitlement answer we got from the store.
///
/// `expiryDate` is what keeps a cached `pro` honest: a device that never reaches RevenueCat
/// again would otherwise stay Pro forever. `updatedAt` records when the answer last *changed*,
/// not every time it was re-confirmed — re-confirmations happen on every foreground and are
/// not worth a Core Data write.
public struct UserProStatus: Hashable, Sendable {

    public let status: ProStatus
    public let expiryDate: Date?
    public let updatedAt: Date?

    public init(status: ProStatus, expiryDate: Date? = nil, updatedAt: Date? = nil) {
        self.status = status
        self.expiryDate = expiryDate
        self.updatedAt = updatedAt
    }

    /// The snapshot a user starts on, before the store has been asked.
    public static let unknown: UserProStatus = .init(status: .unknown)

    /// Whether pro features should be unlocked at `date`.
    ///
    /// A `pro` snapshot whose `expiryDate` has passed reads as not-pro, so an expired
    /// subscription lapses on its own even while the app is offline. A `pro` snapshot with no
    /// `expiryDate` (lifetime, or a non-expiring entitlement) never lapses.
    public func isPro(asOf date: Date) -> Bool {
        guard status == .pro else { return false }
        guard let expiryDate else { return true }
        return expiryDate > date
    }

    /// Whether pro features should be unlocked right now.
    public var isPro: Bool { isPro(asOf: .now) }

    /// `false` while the store has never been reached on this device.
    public var isResolved: Bool { status != .unknown }
}
