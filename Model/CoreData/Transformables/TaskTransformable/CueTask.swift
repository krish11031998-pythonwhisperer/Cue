//
//  CueTask.swift
//  Model
//
//  Created by Krishna Venkatramani on 20/01/2026.
//

import Foundation
import CoreData

public class CueTask: NSObject, NSSecureCoding, Codable {
    public static var supportsSecureCoding: Bool = true
    
    public enum TaskIcon: Hashable, Codable {
        case symbol(String)
        case emoji(String)
        
        init?(iconValue: String) {
            if iconValue.hasPrefix("symbol_") {
                self = .symbol(iconValue.replacingOccurrences(of: "symbol_", with: ""))
            } else if iconValue.hasPrefix("emoji_") {
                self = .emoji(iconValue.replacingOccurrences(of: "emoji_", with: ""))
            } else {
                return nil
            }
        }
        
        var iconValue: String {
            switch self {
            case .symbol(let value):
                return "symbol_\(value)"
            case .emoji(let value):
                return "emoji_\(value)"
            }
        }
    }
    
    public let title: String
    public let icon: TaskIcon

    enum Keys: String, CodingKey {
        case title
        case icon
    }
    
    public init(title: String, icon: TaskIcon) {
        self.title = title
        self.icon = icon
    }
    
    public required init?(coder: NSCoder) {
        let title = coder.decodeObject(of: NSString.self, forKey: Keys.title.rawValue) as? String
        let iconValue = coder.decodeObject(of: NSString.self, forKey: Keys.icon.rawValue) as? String
        
        guard let title,
              let iconValue,
              let icon = TaskIcon(iconValue: iconValue) else {
            fatalError("Can't have empty title and/or icon")
        }
        
        self.title = title
        self.icon = icon
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(title as NSString, forKey: Keys.title.rawValue)
        coder.encode(icon.iconValue as NSString, forKey: Keys.icon.rawValue)
    }
    
    
    // MARK: - isEqual
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Self else { return false }
        return title == other.title && icon == other.icon
    }
    
}
