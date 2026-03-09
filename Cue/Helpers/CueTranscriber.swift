//
//  CueTranscriber.swift
//  Cue
//
//  Created by Krishna Venkatramani on 21/03/2026.
//

import Speech
import AsyncAlgorithms
import NaturalLanguage

class CueTranscriber {
    
    enum Result: Sendable {
        case final(AttributedString)
        case volatile(AttributedString)
    }
    
    private var transcriber: SpeechTranscriber!
    private var analyzer: SpeechAnalyzer!
    private var analyzerFormat : AVAudioFormat!
    
    var converter = BufferConverter()
    
    var downloadModelForLocale: ((Progress) -> Void)?
    
    // Analyzer
    private var inputSequence: AsyncStream<AnalyzerInput>!
    private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation!
    
    // Result
    private var resultContinuation: AsyncStream<Result>.Continuation!
    private(set) var resultStream: AsyncStream<Result>!
    
    public private(set) var transcriptionResult: AsyncStream<Result>!
    
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
        transcriptionResult = .init(unfolding: { [weak self] in
            do {
                for try await result in transcriber.results {
                    if result.isFinal {
                        if let finalizedString = self?.finalizeSentences(String(result.text.characters)) {
                            return Result.final(AttributedString(finalizedString))
                        } else {
                            return Result.final(result.text)
                        }
                    } else {
                        return Result.volatile(result.text)
                    }
                }
            } catch {
                print("(DEBUG) error: ", error.localizedDescription)
            }
            return nil
        })
        
        analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])
        
        (inputSequence, inputBuilder) = AsyncStream<AnalyzerInput>.makeStream()
        
        guard let inputSequence else { return }
        
        do {
            try await analyzer?.start(inputSequence: inputSequence)
        } catch {
            #warning("Need Error to propagate to view!")
            print("(ERROR) error: ", error.localizedDescription)
        }
        print("(DEBUG) Analuzer Setup DONE")
    }
    
    func streamAudioToTranscriber(_ buffer: AVAudioPCMBuffer) throws {
        guard let inputBuilder,
              let analyzerFormat,
              !Task.isCancelled else {
            fatalError("invalid Audio Data type provided here")
        }
        
        let converted = try self.converter.convertBuffer(buffer, to: analyzerFormat)
        let input = AnalyzerInput(buffer: converted)
        
        inputBuilder.yield(input)
    }
    
    func stopTranscribing() async throws {
        inputBuilder?.finish()
        try await analyzer.finalizeAndFinishThroughEndOfInput()
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
