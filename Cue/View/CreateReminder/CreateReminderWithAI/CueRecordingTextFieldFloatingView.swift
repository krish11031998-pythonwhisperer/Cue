//
//  CueRecordingTextFieldFloatingView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 29/03/2026.
//

import SwiftUI
import VanorUI

struct CueTextFieldFocusPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
    }
}

struct CueRecordingTextFieldFloatingView: View {
    
    enum ViewState: Hashable {
        case idle
        case textField
        case voiceRecording
    }
    
    enum SaveState {
        case idle
        case canSave
        case saving
        case saved
        case errorWhileSaving
    }
    
    enum RecordingState {
        case startRecording
        case pauseRecording
        case endRecording
        case idle
    }
    
    static let recordButtonID = "record"
    static let waveformID = "waveform"
    static let confirmID = "confirm"
    
    @State private var viewState: ViewState = .idle
    @State private var recordingState: RecordingState = .idle
    @FocusState private var textFieldIsInFocus: Bool
    @State private var textFieldText: String = ""
    @State private var saveState: SaveState = .idle
    @Namespace private var namespace
    let waveformBarBuilder: AsyncStream<[CGFloat]>?
    let recordingAction: (CueRecorder.RecorderState) -> Void
    let generateReminder: (String) -> Void
    let generating: Bool
    let canSaveGenerated: Bool
    
    private static let maxCharacterLimit: Int = 100
    
    init(generating: Bool,
         canSaveGenerated: Bool,
         waveformBuilder: AsyncStream<[CGFloat]>?,
         recordingAction: @escaping (CueRecorder.RecorderState) -> Void,
         generateReminder: @escaping (String) -> Void) {
        self.recordingAction = recordingAction
        self.generateReminder = generateReminder
        self.waveformBarBuilder = waveformBuilder
        self.generating = generating
        self.canSaveGenerated = canSaveGenerated
    }
    
    var generateButtonDisabled: Bool {
        guard viewState == .textField else { return false }
        return textFieldText.isEmpty || generating
    }
    
    var voiceRecordingSymbol: SFSymbol {
        switch recordingState {
        case .idle:
           return .waveform
        case .pauseRecording:
            return .recordCircle
        case .startRecording, .endRecording:
            return .pauseFill
        }
    }
    
    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                if viewState == .voiceRecording {
                    Button(action: recordButtonAction) {
                        Image(systemSymbol: voiceRecordingSymbol)
                    }
                    .buttonStyle(.accessoryButton(size: .large, color: .clear))
                    .glassEffectID(Self.recordButtonID, in: namespace)
                }

                CueAITextField(viewState: $viewState, textFieldText: $textFieldText, textFieldIsInFocus: $textFieldIsInFocus, generating: generating, generateReminder: generateReminder)
                    .glassEffectID(Self.waveformID, in: namespace)
                
                if viewState == .voiceRecording {
                    Button {
                        viewState = .idle
                    } label: {
                        Image(systemSymbol: .checkmark)
                    }
                    .buttonStyle(.accessoryButton(size: .large, color: .clear))
                    .glassEffectID(Self.confirmID, in: namespace)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, textFieldIsInFocus ? 8 : 0)
        .animation(.easeInOut, value: viewState)
        .preference(key: CueTextFieldFocusPreferenceKey.self, value: textFieldIsInFocus)
        .task(id: recordingState) {
            guard recordingState != .idle else { return }
            switch recordingState {
            case .startRecording:
                recordingAction(.resume)
            case .pauseRecording:
                recordingAction(.pause)
            case .endRecording:
                recordingAction(.stop)
            case .idle:
                break
            }
        }
        .onChange(of: viewState, { oldValue, newValue in
            if oldValue == .idle && newValue == .voiceRecording {
                recordingState = .startRecording
            } else if oldValue == .voiceRecording && newValue == .idle {
                recordingState = .endRecording
            }
        })
        .onChange(of: canSaveGenerated) { _, newValue in
            withAnimation(.snappy) {
                guard newValue else { return saveState = .idle }
                saveState = .canSave
            }
        }
    }
    
    
    // MARK: - Action
    
    private func recordButtonAction() {
        switch recordingState {
        case .startRecording:
            self.recordingState = .pauseRecording
        case .pauseRecording,  .idle:
            self.recordingState = .startRecording
        case .endRecording:
            break
        }
    }
    
    
    
    // MARK: - TextLimitIndicator
    
    struct TextLimitIndicator: View {
        
        let textFieldText: String
        
        var trimToValue: CGFloat {
            1 - CGFloat(textFieldText.count)/CGFloat(CueRecordingTextFieldFloatingView.maxCharacterLimit)
        }
        
        var trimColor: Color {
            switch trimToValue {
            case 0.6...1:
                Color.green
            case 0.3..<0.6:
                Color.orange
            case 0..<0.3:
                Color.red
            default:
                Color.clear
            }
        }
        
        var body: some View {
            HStack(alignment: .center, spacing: 8) {
                ZStack(alignment: .center) {
                    Circle()
                        .fill(Color.clear)
                        .stroke(Color.secondarySystemBackground, lineWidth: 2)
                    Circle()
                        .trim(from: 0, to: trimToValue)
                        .fill(Color.clear)
                        .stroke(trimColor, lineWidth: 2)
                }
                .rotationEffect(.degrees(-90))
                .frame(width: 14, height: 14, alignment: .center)
                
                Text("\(textFieldText.count)/\(CueRecordingTextFieldFloatingView.maxCharacterLimit)")
                    .font(.footnote)
                    .fontWeight(.semibold)
            }
        }
    }
    
    
    // MARK: - TextField
    
    struct CueAITextField: View {
        private static let maxCharacterLimit: Int = 100
        private static let staticTextString: String = "what would you like to plan?"
        @Binding var viewState: ViewState
        @Binding var textFieldText: String
        @State private var sizeOfIdleView: CGSize = .zero
        
        var textFieldIsInFocus: FocusState<Bool>.Binding
        let generating: Bool
        let generateReminder: (String) -> Void
        
        private var generateButtonDisabled: Bool {
            switch viewState {
            case .idle:
                return true
            case .textField:
                return textFieldText.isEmpty || generating
            case .voiceRecording:
                return true
            }
        }
        
        private var cornerRadius: CGFloat {
            guard viewState == .textField else { return sizeOfIdleView.smallDim.half }
            return 24
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                switch viewState {
                case .idle:
                    HStack(alignment: .center, spacing: 8) {
                        Button {
                            self.viewState = .voiceRecording
                        } label: {
                            Image(systemSymbol: .waveform)
                        }
                        .buttonStyle(.accessoryButton(size: .small, color: .green))

                        Text(Self.staticTextString)
                            .font(.bitcountRegular(style: .subheadline))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                self.viewState = .textField
                                self.textFieldIsInFocus.wrappedValue = true
                            }
                            .transition(.opacity)
                    }
                case .textField:
                    TextField(Self.staticTextString, text: $textFieldText, axis: .vertical)
                        .focused(textFieldIsInFocus)
                        .textFieldStyle(.plain)
                        .submitLabel(.go)
                        .frame(maxWidth: .infinity, minHeight: 32, alignment: .topLeading)
                        .autoDismissOnReturn(text: $textFieldText) {
                            self.textFieldIsInFocus.wrappedValue = false
                            self.viewState = .idle
                        }
                        .transition(.opacity)
                    
                    HStack(alignment: .center, spacing: 8) {
                        TextLimitIndicator(textFieldText: textFieldText)
                        Button {
                            generateReminder(textFieldText)
                        } label: {
                            Image(systemSymbol: .checkmark)
                                .opacity(generating ? 0 : 1)
                                .overlay(alignment: .center) {
                                    if generating {
                                        ProgressView()
                                            .tint(Color.proSky.foregroundSecondary)
                                    }
                                }
                        }
                        .buttonStyle(.accessoryButton(size: .small, color: Color.proSky.baseColor))
                        .disabled(generateButtonDisabled)
                        .frame(maxWidth: viewState == .textField ? .infinity: nil, alignment: .trailing)
                    }
                case .voiceRecording:
                    WaveformView()
                        .frame(height: 36)
                }
            }
            .padding(.init(top: 12, leading: 12, bottom: 12, trailing: 12))
            .onGeometryChange(for: CGSize.self, of: { $0.size }, action: { self.sizeOfIdleView = $0 })
            .glassEffect(.regular, in: .roundedRect(cornerRadius: cornerRadius))
            .limitText(textLimit: Self.maxCharacterLimit, text: $textFieldText)
            .onChange(of: viewState) { _, _ in
                self.textFieldText = ""
            }
            .onChange(of: generating) { oldValue, newValue in
                let wasGenerating = (oldValue == true) && (newValue == false)
                if viewState == .textField && wasGenerating {
                    self.textFieldText = ""
                }
            }
        }
    }
    
    
    // MARK: - Save Button
    
    struct SaveButton: View {
        
        var state: SaveState
        let action: () -> Void
        
        var symbol: SFSymbol {
            switch state {
            case .idle:
                fatalError("Shouldn't be active")
            case .canSave:
                return .squareAndArrowDown
            case .saved:
                return .checkmark
            case .errorWhileSaving:
                return .xmark
            case .saving:
                return .progressIndicator
            }
        }
        
        var color: Color {
            switch state {
            case .idle:
                Color.clear
            case .canSave:
                Color.proSky.baseColor
            case .saving:
                Color.proGreen.surfacePrimary
            case .saved:
                Color.proGreen.baseColor
            case .errorWhileSaving:
                Color.proRed.baseColor
            }
        }
        
        var body: some View {
            Button(action: action) {
                Group {
                    switch state {
                    case .idle:
                        Color.clear
                    case .saving:
                        ProgressView()
                    case .canSave, .saved, .errorWhileSaving:
                        Image(systemSymbol: symbol)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                .font(.headline)
                .frame(width: 44, height: 44)
                .glassEffect(.regular.tint(Color.proSky.baseColor), in: .circle)
            }
            .buttonStyle(.plain)
        }
        
    }
    
}
