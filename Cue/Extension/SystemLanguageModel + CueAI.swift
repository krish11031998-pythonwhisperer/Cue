//
//  SystemLanguageModel + CueAI.swift
//  Cue
//
//  Created by Krishna Venkatramani on 20/09/2026.
//

import FoundationModels

extension SystemLanguageModel {
    
    enum CueAIAvailablity: Sendable {
        case available
        case unavailable
        case needsEnablement
        case needsToLoad
    }
    
    /// Whether this device can run cue:ai at all.
    ///
    /// cue:ai generates every reminder through the on-device model, so this is `false` both on
    /// hardware without Apple Intelligence and on a capable device that has it switched off or is
    /// still downloading the model.
    static var supportsCueAI: Bool {
        switch cueAIAvailability {
        case .available, .needsEnablement, .needsToLoad:
            return true
        case .unavailable:
            return false
        }
    }
    
    static var cueAIAvailability: CueAIAvailablity {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            switch reason {
            case .appleIntelligenceNotEnabled:
                return .needsEnablement
            case .modelNotReady:
                return .needsToLoad
            case .deviceNotEligible:
                return .unavailable
            @unknown default:
                return .unavailable
            }
        }
    }
}
