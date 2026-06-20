//
//  CueLanguagareModelSession.swift
//  Cue
//
//  Created by Krishna Venkatramani on 26/06/2026.
//

import FoundationModels
import Foundation

class CueLanguagareModelSession {
    
    enum Result<T>: Sendable {
        case generatedResponse(T)
        case createNewSession
        case error(Error)
    }
    
    private(set) var session: LanguageModelSession
    
    var tools: [any Tool] {
        []
    }
    
    init(session: LanguageModelSession) {
        self.session = session
    }
    
    #warning("Should make it `async throws -> T?`")
    @MainActor
    func generate<T: FoundationModels.Generable>(for prompt: String) async -> T? {
        guard !Task.isCancelled else { return nil }
        let result: Result<T>
        if #available(iOS 27.0, *) {
            result = await newGenerateFromSession(session: session, for: prompt)
        } else {
            result = await generateFromSession(session: session, for: prompt)
        }
        
        switch result {
        case .generatedResponse(let response):
            return response
        case .createNewSession:
            createNewContextualSession()
            return await generate(for: prompt)
        case .error(let error):
            print("(ERROR) \(#function): ", error.localizedDescription)
            return nil
        }
    }
    
    
    // MARK: - iOS 26.0
    
    @concurrent
    private func generateFromSession<T: FoundationModels.Generable>(session: LanguageModelSession, for prompt: String) async -> Result<T> {
            do {
                let prompt = Prompt("Create an reminder of this description: \(prompt)")
                let tasks = try await session.respond(to: prompt,
                                                      generating: T.self,
                                                      includeSchemaInPrompt: true)
                guard !Task.isCancelled else { return .error(Task.CancellationError()) }
                return .generatedResponse(tasks.content)
            } catch let error as LanguageModelSession.GenerationError {
                guard case .exceededContextWindowSize = error else {
                    return .error(error)
                }
                
                return .createNewSession
            } catch {
                return .error(error)
            }
    }
    
    
    // MARK: - iOS 27.0
    
    @available(iOS 27.0, *)
    @concurrent
    private func newGenerateFromSession<T: FoundationModels.Generable>(session: LanguageModelSession, for prompt: String) async -> Result<T> {
        do {
            let prompt = Prompt("Create an reminder of this description: \(prompt)")
            let generatingOptions = GenerationOptions(temperature: 1.0)
            let tasks = try await session.respond(to: prompt,
                                                  generating: T.self,
                                                  includeSchemaInPrompt: true, options: generatingOptions)
            guard !Task.isCancelled else { return .error(Task.CancellationError()) }
            return .generatedResponse(tasks.content)
        } catch let error as LanguageModelError {
            guard case .contextSizeExceeded(let contextSizeExceeded) = error else {
                return .error(error)
            }
            
            return .createNewSession
        } catch {
            return .error(error)
        }
    }
    
    @MainActor
    func createNewContextualSession() {
        let allEntries = session.transcript
        let condensedEntries = [allEntries.first, allEntries.last].compactMap { $0 }
        let condensedTranscript = Transcript(entries: condensedEntries)
        let newSession = LanguageModelSession(tools: tools, transcript: condensedTranscript)
        newSession.prewarm()
        guard !Task.isCancelled else { return }
        self.session = newSession
    }
}
