//
//  CueTaskContainer.swift
//  Cue
//
//  Created by Krishna Venkatramani on 20/01/2026.
//

import CoreData

@objc(CueTaskContainer)
public class CueTaskContainer: NSObject, NSSecureCoding, Codable {
    public static var supportsSecureCoding: Bool = true
    
    public var tasks: [CueTask]
    
    enum Keys: String, CodingKey {
        case tasks
    }
    
    public required init?(coder: NSCoder) {
        guard let tasks = coder.decodeArrayOfObjects(ofClass: CueTask.self, forKey: Keys.tasks.rawValue) else { return nil }
        self.tasks = tasks
    }
    
    public init(tasks: [CueTask]) {
        self.tasks = tasks
    }
    
    public func encode(with coder: NSCoder) {
        coder.encode(tasks, forKey: Keys.tasks.rawValue)
    }
    
    // MARK: - Equality
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CueTaskContainer else { return false }
        return other.tasks == self.tasks
    }
}
