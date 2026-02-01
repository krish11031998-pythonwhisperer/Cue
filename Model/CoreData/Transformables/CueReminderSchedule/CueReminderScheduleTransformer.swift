//
//  CueReminderScheduleTransformer.swift
//  Cue
//
//  Created by Krishna Venkatramani on 27/01/2026.
//

import Foundation
import CoreData

@objc(CueReminderScheduleTransformer)
class CueReminderScheduleTransformer: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard let cueIcon = value as? CueReminderSchedule else { return nil }
        
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
            let cueIcon = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [CueReminderSchedule.self, NSSet.self, NSNumber.self, NSDate.self], from: data)
            return cueIcon
        } catch {
            print(error)
            return nil
        }
    }
    
    
    static func register() {
        let name = NSValueTransformerName("CueReminderScheduleTransformer")
        ValueTransformer.setValueTransformer(CueReminderScheduleTransformer(), forName: name)
    }
}
