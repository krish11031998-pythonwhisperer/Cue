//
//  CueRecorder.swift
//  Cue
//
//  Created by Krishna Venkatramani on 21/03/2026.
//

import AVFoundation
import VanorUI

class CueRecorder {
    
    typealias AudioBufferStream = AsyncStream<AVAudioPCMBuffer>
    
    enum RecorderError: Error, LocalizedError {
        case accessToMicrophoneDenied
        
        var errorDescription: String? {
            switch self {
            case .accessToMicrophoneDenied:
                "No Access to Microphone is denied."
            }
        }
        
        var failureReason: String? {
            return nil
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .accessToMicrophoneDenied:
                return "Go to Settings and re-enable micrphone"
            }
        }
    }
    
    enum RecorderState {
        case resume
        case stop
        case pause
        case idle
    }
    
    private(set) var recorderState: RecorderState = .idle
    private let audioEngine: AVAudioEngine
    nonisolated private let audioBufferStreamPublisher: StreamProvider<AVAudioPCMBuffer> = .init()
    
    var waveformBarsBuilderFromAVAudioPCMBuffer: AsyncStream<[CGFloat]>?
    
    init() {
        self.audioEngine = .init()
    }
    
    func setupRecorder() async throws {
        if recorderState != .idle {
            await stopAudioSession()
        }
        guard try await authorizeMicrophone() else { return }
        
        #if os(iOS)
        try await self.setUpAudioSession()
        #endif

        try setupAudioStream()
    }
    
    
    // MARK: - Authorization
    
    private func authorizeMicrophone() async throws -> Bool {
        let currentAccess = await AVCaptureDevice.requestAccess(for: .audio)
        
        if currentAccess {
            return true
        }
        
        throw RecorderError.accessToMicrophoneDenied
    }
    
    
    // MARK: - Setup Audio
    
#if os(iOS)
    @concurrent
    private func setUpAudioSession() async throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .default)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    @concurrent
    private func stopAudioSession() async {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            if #available(iOS 27.0, *) {
                let hasDeactivated = try await audioSession.deactivate()
                if hasDeactivated {
                    await MainActor.run {
                        recorderState = .idle
                    }
                }
            } else {
                try audioSession.setActive(false)
                await MainActor.run {
                    recorderState = .idle
                }
            }
        } catch {
            print("(ERROR) failed to stop the audioSession: ", error.localizedDescription)
        }
    }
#endif
    
    private func setupAudioStream() throws {
        // Remove Tap on Bus
        audioEngine.inputNode.removeTap(onBus: 0)
        
        audioEngine.inputNode.installTap(onBus: 0,
                                         bufferSize: 4096,
                                         format: audioEngine.inputNode.outputFormat(forBus: 0)) { [weak self] (buffer, time) in
            self?.audioBufferStreamPublisher.yield(buffer)
        }
        
        print("(DEBUG) audioEngine installedTap!")
        audioEngine.prepare()
        print("(DEBUG) audioEngine prepare!")
    }
    
    
    // MARK: - Audio Player State Management
    
    nonisolated func audioStream() -> AsyncStream<AVAudioPCMBuffer> {
        audioBufferStreamPublisher.makeStream()
    }
    
    func pause() {
        audioEngine.pause()
        recorderState = .pause
    }
    
    func startOrResume() throws {
        try audioEngine.start()
        recorderState = .resume
    }
    
    func stop() {
        Task {
            audioEngine.stop()
            await stopAudioSession()
            recorderState = .idle
        }
    }
}
