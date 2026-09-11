//
//  FocusSessionIntents.swift
//  Cue
//
//  Created by Krishna Venkatramani on 11/09/2026.
//

import AppIntents
import Foundation

// NOTE: this file is compiled into BOTH `Kyu` and `CueWidgets` on purpose.
// AppIntents metadata extraction runs per target, and iOS only resolves intents that the
// running binary itself advertises - an intent defined in a framework lands in that
// framework's `Metadata.appintents` and is invisible to the app and the extension.
// `CueWidgets` needs the type to build `Button(intent:)`; `Kyu` needs it to perform it.

/// Implemented by the app's focus session coordinator.
@MainActor
protocol FocusSessionIntentHandler: AnyObject {
    func toggleTimerFromLiveActivity()
}

/// The app registers its live coordinator here. `LiveActivityIntent.perform()` runs in the
/// *app's* process, so the intent only has to forward the tap to whatever is registered.
/// The copy compiled into the widget extension is simply never populated.
@MainActor
final class FocusSessionIntentRouter {
    static let shared = FocusSessionIntentRouter()
    weak var handler: (any FocusSessionIntentHandler)?
    private init() {}
}

struct ToggleFocusSessionIntent: LiveActivityIntent {
    
    static let title: LocalizedStringResource = "Pause or Resume Focus Session"
    static let description = IntentDescription("Pauses or resumes the running focus session.")
    
    /// Handle the tap in the background - foregrounding the app just to pause is jarring.
    static let openAppWhenRun: Bool = false
    
    init() {}
    
    @MainActor
    func perform() async throws -> some IntentResult {
        FocusSessionIntentRouter.shared.handler?.toggleTimerFromLiveActivity()
        return .result()
    }
}
