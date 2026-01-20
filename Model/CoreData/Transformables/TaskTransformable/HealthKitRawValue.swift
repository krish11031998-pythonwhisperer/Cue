//
//  HealthKitRawValue.swift
//  Cue
//
//  Created by Krishna Venkatramani on 20/01/2026.
//

import Foundation

class HealthKitRawValue: NSObject, NSSecureCoding {
    
    var rawValue: Int
    
    init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    static var supportsSecureCoding: Bool { true }
    
    func encode(with coder: NSCoder) {
        coder.encode(rawValue, forKey: "rawValue")
    }
    
    required init?(coder: NSCoder) {
        self.rawValue = coder.decodeInteger(forKey: "rawValue")
    }
    
}

@objc(HealthKitRawValuesContainer)
class HealthKitRawValuesContainer: NSObject, NSSecureCoding {
    var rawValues: [HealthKitRawValue]
    
    init(rawValues: [HealthKitRawValue]) {
        self.rawValues = rawValues
    }
    
    static var supportsSecureCoding: Bool { true }
    
    func encode(with coder: NSCoder) {
        coder.encode(rawValues, forKey: "rawValues")
    }
    
    required init?(coder: NSCoder) {
        self.rawValues = coder.decodeArrayOfObjects(ofClass: HealthKitRawValue.self, forKey: "rawValues") ?? []
    }
}

class HealthKitRawValuesTransformer: ValueTransformer {
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let healthKitRawValueContainer = value as? HealthKitRawValuesContainer else {
            return nil
        }
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: healthKitRawValueContainer, requiringSecureCoding: true)
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
            let motorConfiguration = try NSKeyedUnarchiver
                .unarchivedObject(ofClasses: [
                    HealthKitRawValuesContainer.self, NSDictionary.self,
                    NSArray.self, NSNumber.self],
                                  from: data)
            return motorConfiguration
        } catch {
            print(error)
            return nil
        }
    }
    
    static func register() {
        let name = NSValueTransformerName("HealthKitRawValuesTransformer")
        ValueTransformer.setValueTransformer(HealthKitRawValuesTransformer(), forName: name)
    }
}
