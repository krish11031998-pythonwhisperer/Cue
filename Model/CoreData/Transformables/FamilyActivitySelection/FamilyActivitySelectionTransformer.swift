//
//  FamilyActivitySelectionTransformer.swift
//  Model
//
//  Created by Krishna Venkatramani on 24/08/2026.
//

import Foundation
import CoreData

@objc(FamilyActivitySelectionTransformer)
class FamilyActivitySelectionTransformer: ValueTransformer {
    override func transformedValue(_ value: Any?) -> Any? {
        guard let box = value as? FamilyActivitySelectionBox else { return nil }

        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: box, requiringSecureCoding: true)
            return data
        } catch {
            print(error)
            return nil
        }
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }

        do {
            let box = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [FamilyActivitySelectionBox.self, NSData.self], from: data)
            return box
        } catch {
            print(error)
            return nil
        }
    }

    static func register() {
        let name = NSValueTransformerName("FamilyActivitySelectionTransformer")
        ValueTransformer.setValueTransformer(FamilyActivitySelectionTransformer(), forName: name)
    }
}
