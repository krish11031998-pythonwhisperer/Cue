//
//  AppSheildAlert.swift
//  Cue
//
//  Created by Krishna Venkatramani on 19/09/2026.
//

import Foundation
import FamilyControls
import SwiftUI
import VanorUI

public enum CueAlertAction: Identifiable {
    case ok
    case cancel
    case customAction(String, Callback)
    
    var buttonRole: ButtonRole {
        switch self {
        case .ok, .customAction:
            return .confirm
        case .cancel:
            return .cancel
        }
    }
    
    public var id: String { buttonTitle }
    
    var buttonAction: Callback? {
        switch self {
        case .ok, .cancel:
            return nil
        case .customAction(_, let callback):
            return callback
        }
    }
    
    var buttonTitle: String {
        switch self {
        case .ok:
            return "OK"
        case .cancel:
            return "Cancel"
        case .customAction(let string, _):
            return string
        }
    }
}

public protocol CueAlertError: Error, LocalizedError {
    var actions: [CueAlertAction] { get }
}

public struct CueAlert<AlertError>: ViewModifier where AlertError: CueAlertError {
    
    @Binding var alert: AlertError?
    
    var message: String {
        guard let failureReason = alert?.failureReason else { return "Something went wrong, try again later" }
        
        guard let recoverySuggestion = alert?.recoverySuggestion else { return failureReason }
        
        return "\(failureReason)\n\n\(recoverySuggestion)"
    }
    
    public func body(content: Content) -> some View {
        content
            .alert(isPresented: .init(get: { alert != nil } , set: { _ in alert = nil }),
                   error: alert) { alert in
                ForEach(alert.actions) { action in
                    Button(action.buttonTitle, role: action.buttonRole) {
                        action.buttonAction?()
                    }
                }
            } message: { alert in
                Text(message)
            }
    }
}

public extension View {
    func cueAlert<Alert: CueAlertError>(alert: Binding<Alert?>) -> some View {
        self.modifier(CueAlert(alert: alert))
    }
}


// MARK: - Testing

fileprivate struct AlertTestView: View {
    
    enum Alert: String, Error, LocalizedError, Identifiable, CueAlertError, CaseIterable {
        case ok
        case cancel
        case customError
        
        var actions: [CueAlertAction] {
            switch self {
            case .ok, .cancel:
                return [.ok, .cancel]
            case .customError:
                return [.customAction("Do Something", { print("Doing Something") })]
            }
        }
        
        var errorDescription: String? {
            switch self {
            case .ok:
                return "Simple Ok Alert"
            case .cancel:
                return "Simple Cancel Alert"
            case .customError:
                return "Custom Error with an message"
            }
        }
        
        var failureReason: String? {
            "This is an simple error message for \(rawValue)"
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .ok, .cancel:
                return "Just tap on OK or Cancel"
            case .customError:
                return "Tap on 'Do Something'"
            }
        }
        
        var id: String { localizedDescription }
    }
    
    @State private var alert: Alert? = nil
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            ForEach(Alert.allCases) { alert in
                Button {
                    self.alert = alert
                } label: {
                    Text(alert.rawValue)
                }
                .tint(.blue)
                .buttonStyle(.glassProminent)
            }
        }
        .cueAlert(alert: $alert)
    }
}

#Preview {
    AlertTestView()
}
