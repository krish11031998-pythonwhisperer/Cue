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
    
    public let title: String
    public let icon: String

    enum Keys: String, CodingKey {
        case title
        case icon
    }
    
    public init(title: String, icon: String) {
        self.title = title
        self.icon = icon
    }
    
    public required init?(coder: NSCoder) {
        let title = coder.decodeObject(of: NSString.self, forKey: Keys.title.rawValue) as? String
        let icon = coder.decodeObject(of: NSString.self, forKey: Keys.title.rawValue) as? String
        
        guard let title, let icon else {
            fatalError("Can't have empty title and/or icon")
        }
        
        self.title = title
        self.icon = icon
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(title as NSString, forKey: Keys.title.rawValue)
        coder.encode(icon as NSString, forKey: Keys.icon.rawValue)
    }
    
    
    // MARK: - isEqual
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Self else { return false }
        return title == other.title && icon == other.icon
    }
    
}
