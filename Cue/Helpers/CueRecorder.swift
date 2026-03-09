//
//  CueRecorder.swift
//  Cue
//
//  Created by Krishna Venkatramani on 21/03/2026.
//

import AVFoundation

class CueRecorder {
    
    typealias AudioBufferStream = AsyncStream<AVAudioPCMBuffer>
    
    enum RecorderState {
        case resume
        case stop
        case pause
        case idle
    }
    
    private(set) var recorderState: RecorderState = .idle
//    private var outputContinuation: AudioBufferStream.Continuation?
//    private let transcriber: CueTranscriber
    private(set) var audioStream: AudioBufferStream?
    private let audioEngine: AVAudioEngine
    var playerNode: AVAudioPlayerNode!
    
    var waveformBarsBuilderFromAVAudioPCMBuffer: AsyncStream<[CGFloat]>?
    
//    var transcribedTextStream: AsyncStream<CueTranscriber.Result> {
//        transcriber.resultStream
//    }
    
//    init(transcriber: CueTranscriber) {
    init() {
//        self.transcriber = transcriber
        self.audioEngine = .init()
    }
    
    func setupRecorder() async {
        if recorderState != .idle {
            stopAudioSession()
        }
        guard await authorizeMicrophone() else { return }
        
        #if os(iOS)
        do {
            try self.setUpAudioSession()
        } catch {
            print("ERROR while setting up the audio session: ", error.localizedDescription)
        }
        #endif
//        await transcriber.setupTranscriber()
        do {
            self.audioStream = try setupAudioStream()
        } catch {
            print("ERROR while setting up the audio stream: ", error.localizedDescription)
        }
    }
    
    
    // MARK: - Authorization
    
    private func authorizeMicrophone() async -> Bool {
        let currentAccess = await AVCaptureDevice.requestAccess(for: .audio)
        
        if currentAccess {
            return true
        }
        
        return await AVCaptureDevice.requestAccess(for: .audio)
    }
    
    
    // MARK: - Setup Audio
    
#if os(iOS)
    private func setUpAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .spokenAudio)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    private func stopAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false)
            recorderState = .idle
        } catch {
            print("(ERROR) failed to stop the audioSession: ", error.localizedDescription)
        }
    }
#endif
    
    private func setupAudioStream() throws -> AudioBufferStream {
        // Remove Tap on Bus
        audioEngine.inputNode.removeTap(onBus: 0)
        
        let audioStream = AudioBufferStream(bufferingPolicy: .bufferingNewest(10)) { continuation in
            audioEngine.inputNode.installTap(onBus: 0,
                                             bufferSize: 4096,
                                             format: audioEngine.inputNode.outputFormat(forBus: 0)) { [weak self] (buffer, time) in
                continuation.yield(buffer)
            }
            continuation.onTermination = { _ in
                print("(DEBUG) audioEngine.continuation is terminated")
            }
        }
        
        print("(DEBUG) audioEngine installedTap!")
        audioEngine.prepare()
        print("(DEBUG) audioEngine prepare!")
        return audioStream
    }
    
    
    // MARK: - Audio Player State Management
    
    func pause() {
        audioEngine.pause()
        recorderState = .pause
    }
    
    func startOrResume() {
        do {
            try audioEngine.start()
            recorderState = .resume
        } catch {
            #warning("Propagate Error to View")
            print("(ERROR) error while starting audioEngine: ", error.localizedDescription)
        }
    }
    
    func stop() {
        audioEngine.stop()
//        outputContinuation?.finish()
        stopAudioSession()
    }
}
