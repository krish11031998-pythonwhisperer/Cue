//
//  CuewIcon.swift
//  Cue
//
//  Created by Krishna Venkatramani on 25/01/2026.
//

import Foundation
import CoreData

public class CueIcon: NSObject, NSSecureCoding, Codable {
    
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
        if let symbol {
            coder.encode(symbol as NSString, forKey: Keys.symbol.rawValue)
        }
        
        if let emoji {
            coder.encode(emoji as NSString, forKey: Keys.emoji.rawValue)
        }
    }
    
    // MARK: - isEqual
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Self else { return false }
        return emoji == other.emoji || symbol == other.symbol
    }
}
