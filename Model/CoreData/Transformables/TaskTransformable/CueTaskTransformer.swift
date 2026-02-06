//
//  CueTaskTransformer.swift
//  Cue
//
//  Created by Krishna Venkatramani on 20/01/2026.
//

import Foundation

@objc(CueTaskTransformer)
class CueTaskTransformer: ValueTransformer {
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let cueTaskContainer = value as? CueTaskContainer else {
            return nil
        }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: cueTaskContainer, requiringSecureCoding: true)
            return data
        } catch {
            print(error)
            return nil
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else {
            print("\(#function) nil data value")
            return nil
        }
        
        do {
            let cueTask = try NSKeyedUnarchiver
                .unarchivedObject(ofClass: CueTaskContainer.self,
                                  from: data)
            return cueTask
        } catch {
            print(error)
            return nil
        }
    }
    
    static func register() {
        let name = NSValueTransformerName("CueTaskTransformer")
        ValueTransformer.setValueTransformer(CueTaskTransformer(), forName: name)
    }
    
}
