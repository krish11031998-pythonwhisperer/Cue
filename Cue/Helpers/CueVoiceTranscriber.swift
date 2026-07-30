//
//  CueVoiceTranscriber.swift
//  Cue
//
//  Created by Krishna Venkatramani on 19/04/2026.
//


import Foundation
import VanorUI

class CueVoiceTranscriber {
    
    private let transcriber: CueTranscriber = .init()
    private let recorder: CueRecorder = .init()
    private var isVoiceRecorderSetup: Bool = false
    private var streamingTask: Task<Void, Never>?
    private(set) var audioWaveformManager: AudioWaveformManager = .init()
    func setup() async {
        do {
            // Setup Audio Recording
            try await recorder.setupRecorder()
            // Setup Transcriber
            await transcriber.setupTranscriberAndAnalyzer()
        } catch {
            print("(ERROR) error: ", error.localizedDescription)
        }
        streamingTask = Task {
            // Start Streaming Audio Buffer → Transcriber
            await startStreamingBufferToTranscriber()
        }
    }
    
    nonisolated func startStreamingBufferToTranscriber() async {
        let audioStream = recorder.audioStream()
        do {
            for await buffer in audioStream {
                async let transcription = try transcriber.streamAudioToTranscriber(buffer)
                async let waveform = audioWaveformManager.process(buffer: buffer)
                _ = try? await (transcription, waveform)
            }
        } catch {
            print("(ERROR) error: ", error.localizedDescription)
        }
    }
    
    func transcriptionStream() -> AsyncStream<CueTranscriber.Result> {
        return transcriber.resultStreamProvider.makeStream()
    }
    
    
    // MARK: - Setup Voice Recorder
    
    func setupIfRequired() async {
        if !isVoiceRecorderSetup {
            isVoiceRecorderSetup = true
            await setup()
        } else {
            streamingTask = Task {
                // Start Streaming Audio Buffer → Transcriber
                await startStreamingBufferToTranscriber()
            }
        }
    }
    
    
    // MARK: - Recorder
    
    func startOrResume() async {
        await setupIfRequired()
        recorder.startOrResume()
    }
    
    func pause() {
        recorder.pause()
    }
    
    func stop() async {
        streamingTask?.cancel()
        recorder.stop()
        await transcriber.stopTranscribing()
        isVoiceRecorderSetup = false
    }
}
