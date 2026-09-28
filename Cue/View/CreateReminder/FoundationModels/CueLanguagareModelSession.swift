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

    /// `nil` keeps the default sampling of each iOS version.
    var generationOptions: GenerationOptions? {
        nil
    }

    /// Sessions whose instructions already show an example of every field can skip the schema,
    /// which shortens every prompt.
    var includesSchemaInPrompt: Bool {
        true
    }

    /// Runs every request on a clean session holding only the instructions, so earlier requests
    /// can't bias later ones and overlapping requests never share a session.
    var usesFreshSessionPerRequest: Bool {
        false
    }

    /// Start of every prompt, cached ahead of time by `prewarm(promptPrefix:)`.
    static let promptPrefix = "Create an reminder of this description: "

    init(session: LanguageModelSession) {
        self.session = session
    }

    #warning("Should make it `async throws -> T?`")
    @concurrent
    func generate<T: FoundationModels.Generable>(for prompt: String) async -> T? {
        guard !Task.isCancelled else { return nil }
        let requestSession = await sessionForRequest()
        let result: Result<T>
        if #available(iOS 27.0, *) {
            result = await newGenerateFromSession(session: requestSession, for: prompt)
        } else {
            result = await generateFromSession(session: requestSession, for: prompt)
        }
        
        switch result {
        case .generatedResponse(let response):
            return response
        case .createNewSession:
            await createNewContextualSession()
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
                let prompt = Prompt("\(Self.promptPrefix)\(prompt)")
                let tasks = try await session.respond(to: prompt,
                                                      generating: T.self,
                                                      includeSchemaInPrompt: includesSchemaInPrompt,
                                                      options: generationOptions ?? GenerationOptions())
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
            let prompt = Prompt("\(Self.promptPrefix)\(prompt)")
            let generatingOptions = generationOptions ?? GenerationOptions(temperature: 1.0)
            let tasks = try await session.respond(to: prompt,
                                                  generating: T.self,
                                                  includeSchemaInPrompt: includesSchemaInPrompt, options: generatingOptions)
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
    
    /// With `usesFreshSessionPerRequest`, hands the current (already prewarmed) session to the
    /// request and replaces it with a new, prewarmed one holding only the instructions.
    @MainActor
    private func sessionForRequest() -> LanguageModelSession {
        guard usesFreshSessionPerRequest else { return session }
        let requestSession = session
        let instructions = [session.transcript.first].compactMap { $0 }
        let newSession = LanguageModelSession(tools: tools, transcript: Transcript(entries: instructions))
        newSession.prewarm(promptPrefix: Prompt(Self.promptPrefix))
        session = newSession
        return requestSession
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
