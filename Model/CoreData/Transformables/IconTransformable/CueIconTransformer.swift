//
//  CueIconTransformable.swift
//  Cue
//
//  Created by Krishna Venkatramani on 25/01/2026.
//

import Foundation

@objc(CueIconTransformer)
class CueIconTransformer: ValueTransformer {
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let cueIcon = value as? CueIcon else { return nil }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: cueIcon, requiringSecureCoding: true)
            return data
        } catch {
            print(error)
            return nil
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        
        do {
            let cueIcon = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [CueIcon.self, NSString.self, NSNumber.self], from: data)
            return cueIcon
        } catch {
            print(error)
            return nil
        }
    }
    
    
    static func register() {
        let name = NSValueTransformerName("CueIconTransformer")
        ValueTransformer.setValueTransformer(CueIconTransformer(), forName: name)
    }
    
}
