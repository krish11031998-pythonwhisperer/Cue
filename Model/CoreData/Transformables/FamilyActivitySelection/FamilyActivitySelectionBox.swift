//
//  FamilyActivitySelectionBox.swift
//  Model
//
//  Created by Krishna Venkatramani on 24/08/2026.
//

import Foundation
import FamilyControls

@objc(FamilyActivitySelectionBox)
public final class FamilyActivitySelectionBox: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let selection: FamilyActivitySelection

    public init(selection: FamilyActivitySelection) {
        self.selection = selection
    }

    public init?(coder: NSCoder) {
        guard let data = coder.decodeObject(of: NSData.self, forKey: "selectionData") as Data?,
              let selection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return nil
        }
        self.selection = selection
    }

    public func encode(with coder: NSCoder) {
        guard let data = try? JSONEncoder().encode(selection) else { return }
        coder.encode(data as NSData, forKey: "selectionData")
    }
}
