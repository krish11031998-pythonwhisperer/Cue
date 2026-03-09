//
//  CueVoiceTranscriber.swift
//  Cue
//
//  Created by Krishna Venkatramani on 19/04/2026.
//


import Foundation
class CueVoiceTranscriber {
    
    private let transcriber: CueTranscriber = .init()
    private let recorder: CueRecorder = .init()
    private var isVoiceRecorderSetup: Bool = false
    private var streamingTask: Task<Void, Never>?
    
    func setup() async {
        // Setup Audio Recording
        await recorder.setupRecorder()
        // Setup Transcriber
        await transcriber.setupTranscriberAndAnalyzer()
        streamingTask = Task {
            // Start Streaming Audio Buffer → Transcriber
            await startStreamingBufferToTranscriber()
        }
    }
    
    func startStreamingBufferToTranscriber() async {
        guard let audioStream = recorder.audioStream else { return }
        
        do {
            for await buffer in audioStream {
                try transcriber.streamAudioToTranscriber(buffer)
            }
        } catch {
            print("(ERROR) error: ", error.localizedDescription)
        }
    }
    
    func transcriptionStream() -> AsyncStream<CueTranscriber.Result> {
        return transcriber.transcriptionResult
    }
    
    
    // MARK: - Setup Voice Recorder
    
    func setupIfRequired() async {
        guard !isVoiceRecorderSetup else { return }
        isVoiceRecorderSetup = true
        await setup()
    }
    
    
    // MARK: - Recorder
    
    func startOrResume() async {
        await setupIfRequired()
        recorder.startOrResume()
    }
    
    func pause() {
        recorder.pause()
    }
    
    func stop() {
        recorder.stop()
        streamingTask?.cancel()
    }
}
