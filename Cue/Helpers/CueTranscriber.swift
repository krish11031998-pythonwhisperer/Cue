//
//  CueTranscriber.swift
//  Cue
//
//  Created by Krishna Venkatramani on 21/03/2026.
//

import Speech
import AsyncAlgorithms
import NaturalLanguage
import VanorUI

class CueTranscriber {
    
    enum Result: Sendable {
        case final(AttributedString)
        case volatile(AttributedString)
    }
    
    private var transcriber: SpeechTranscriber!
    private var analyzer: SpeechAnalyzer!
    nonisolated(unsafe) private var analyzerFormat : AVAudioFormat!
    
    var converter = BufferConverter()
    
    var downloadModelForLocale: ((Progress) -> Void)?
    
    // Analyzer
    private var inputSequence: AsyncStream<AnalyzerInput>!
    nonisolated(unsafe) private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation!
    
    // Analyzer → Transcriber
    private var transcriptionTask: Task<Void, Never>?
    
    // Result
    nonisolated let resultStreamProvider: StreamProvider<Result> = .init()
  
    func setupTranscriberAndAnalyzer() async {
        transcriber = SpeechTranscriber(locale: Locale.current,
                                        transcriptionOptions: [],
                                        reportingOptions: [.fastResults, .volatileResults],
                                        attributeOptions: [.transcriptionConfidence])
        
        guard let transcriber else {
            #warning("Need to throw error: Setup of failed Transcriber")
            return
        }
        
        analyzer = SpeechAnalyzer(modules: [transcriber])
        
        #warning("Ensure the model is available")
        do {
            try await ensureModel(transcriber: transcriber, locale: Locale.current)
        } catch {
            #warning("Propagate error to view")
            print("(ERROR) error while downloading models: ", error.localizedDescription)
        }
        
        // Setup Transcription Result
        transcriptionTask = Task { [weak resultStreamProvider] in
            do {
                for try await result in transcriber.results {
                    if result.isFinal {
                        resultStreamProvider?.yield(.final(result.text))
                    } else {
                        resultStreamProvider?.yield(.volatile(result.text))
                    }
                }
            } catch {
                print("(ERROR) error: ", error.localizedDescription)
            }
        }
        
        analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])
        
        (inputSequence, inputBuilder) = AsyncStream<AnalyzerInput>.makeStream()
        
        inputBuilder.onTermination = {
            print("(DEBUG) inputBuilder is terminated: ", $0)
        }
        
        guard let inputSequence else { return }
        
        do {
            try await analyzer?.start(inputSequence: inputSequence)
        } catch {
            #warning("Need Error to propagate to view!")
            print("(ERROR) error: ", error.localizedDescription)
        }
        print("(DEBUG) Analuzer Setup DONE")
    }
    
    @MainActor
    func streamAudioToTranscriber(_ buffer: AVAudioPCMBuffer) async throws {
        guard let inputBuilder,
              let analyzerFormat else {
            fatalError("invalid Audio Data type provided here")
        }
        
        guard !Task.isCancelled else {
            return
        }
        
        let converted = try BufferConverter.convertBuffer(buffer, to: analyzerFormat)
        let input = AnalyzerInput(buffer: converted)
        
        inputBuilder.yield(input)
    }
    
    func stopTranscribing() async {
        inputBuilder?.finish()
        await analyzer?.cancelAndFinishNow()
        transcriptionTask?.cancel()
    }
    
    
    // MARK: - Helpers
    
    private func finalizeSentences(_ string: String) -> String? {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = string
        
        var sentences: [String] = []
        tokenizer.enumerateTokens(in: string.startIndex..<string.endIndex) { range, _ in
            let sentence = String(string[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            sentences.append(sentence)
            return true
        }
        
        print("(DEBUG) all sentences recognized: \(sentences)")
        return sentences.first
    }
}


extension CueTranscriber {
    public func ensureModel(transcriber: SpeechTranscriber, locale: Locale) async throws {
        guard await supported(locale: locale) else {
            throw NSError(domain: "locale not supported", code: -1010)
        }
        
        if await installed(locale: locale) {
            return
        } else {
            try await downloadIfNeeded(for: transcriber)
        }
    }
    
    func supported(locale: Locale) async -> Bool {
        let supported = await SpeechTranscriber.supportedLocales
        return supported.map { $0.identifier(.bcp47) }.contains(locale.identifier(.bcp47))
    }

    func installed(locale: Locale) async -> Bool {
        let installed = await Set(SpeechTranscriber.installedLocales)
        return installed.map { $0.identifier(.bcp47) }.contains(locale.identifier(.bcp47))
    }

    func downloadIfNeeded(for module: SpeechTranscriber) async throws {
        if let downloader = try await AssetInventory.assetInstallationRequest(supporting: [module]) {
////            self.downloadProgress = downloader.progress
//            downloader.progress.observe(\.fractionCompleted) { _, fractionCompleted in
//                print("(DEBUG) Download: ", fractionCompleted)
//            }
            downloadModelForLocale?(downloader.progress)
            try await downloader.downloadAndInstall()
        }
    }
    
}
