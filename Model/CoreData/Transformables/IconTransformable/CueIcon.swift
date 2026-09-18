//
//  CuewIcon.swift
//  Cue
//
//  Created by Krishna Venkatramani on 25/01/2026.
//

import Foundation
import CoreData

@objc(CueIcon)
public class CueIcon: NSObject, NSSecureCoding, Codable, @unchecked Sendable {
    
    public static var supportsSecureCoding: Bool { true }
    
    public let symbol: String?
    public let emoji: String?

    public init(symbol: String?, emoji: String?) {
        self.symbol = symbol
        self.emoji = emoji
    }
    
    enum Keys: String, CodingKey {
        case symbol
        case emoji
    }
    
    
    // MARK: - Codable
    
    public required init?(coder: NSCoder) {
        let symbol = coder.decodeObject(of: NSString.self, forKey: Keys.symbol.rawValue) as? String
        let emoji = coder.decodeObject(of: NSString.self, forKey: Keys.emoji.rawValue) as? String
        
        if symbol == nil && emoji == nil {
            fatalError("Can't have empty symbol and emoji")
        }
        
        self.symbol = symbol
        self.emoji = emoji
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(symbol as? NSString, forKey: Keys.symbol.rawValue)
        coder.encode(emoji as? NSString, forKey: Keys.emoji.rawValue)
    }
    
    // MARK: - isEqual
    
    /// Two icons are the same only when *both* halves match. Using `||` here made every
    /// emoji-only icon equal to every other emoji-only icon (their `symbol` is `nil` on
    /// both sides), which silently swallowed emoji edits: `ReminderModel`, `CalendarDay`
    /// and friends are `Hashable` over this object, so a reminder whose emoji was the only
    /// thing that changed compared equal to its previous value and the `task(id:)`
    /// refreshes driving the calendar never re-ran.
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CueIcon else { return false }
        return emoji == other.emoji && symbol == other.symbol
    }
    
    
    // MARK: - hash
    
    /// `NSObject`'s default hash is identity based, so two `CueIcon`s carrying the same
    /// emoji hashed differently even though they are equal. That breaks the `Hashable`
    /// contract for every value type embedding an icon (`ReminderModel`, `ReminderTaskModel`)
    /// and makes the hash-derived view IDs churn on each Core Data fetch.
    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(symbol)
        hasher.combine(emoji)
        return hasher.finalize()
    }
}
