//
//  ReminderSubtaskSession.swift
//  Cue
//
//  Created by Krishna Venkatramani on 24/01/2026.
//

import FoundationModels
import VanorUI
import Foundation

@Generable
struct SuggestedSubTask {
    @Guide(description: "Title of the sub-task")
    var title: String
    @Guide(.anyOf(EmojiCategory.objects.emojis.map(\.char)))
    var icon: String
}

@Generable
struct SuggestedSubTasks {
    
    @Guide(.count(6))
    var subTasks: [SuggestedSubTask]
    
    static var promptExample: String {
        "Give me sub-tasks for 'Go to Gym'"
    }
    
    static var example: SuggestedSubTasks {
        let subTasks: [SuggestedSubTask] = [
            .init(title: "Warm up", icon: SFSymbol.figureStrengthtrainingFunctional.rawValue),
            .init(title: "Exercise", icon: SFSymbol.figureStrengthtrainingTraditional.rawValue),
            .init(title: "Warm down", icon: SFSymbol.figureYoga.rawValue)
        ]
        
        return .init(subTasks: subTasks)
    }
}

class ReminderSubtaskSession {
    
    let session: LanguageModelSession
    
    init() {
        session = .init(model: .init(useCase: .general, guardrails: .permissiveContentTransformations),
                        instructions: {
            """
            You are reminder generator, you sole purpose is to suggest sub-tasks for a given title of the task. Make sure it is cohorent to the task that for a given reminder title
            
            For Example if I say \(SuggestedSubTasks.promptExample). 
            I expect you to give me something cohorent like the following
            """
            SuggestedSubTasks.example
        })
    }
    
    func suggestionTasks(for title: String) async -> SuggestedSubTasks? {
        do {
            let prompt = Prompt("Suggest me tasks for the given Task Title: \(title)")
            let tasks = try await session.respond(to: prompt,
                                                  generating: SuggestedSubTasks.self,
                                                  includeSchemaInPrompt: true)
            return tasks.content
        } catch {
            print("(DEBUG) There was an error: \(error.localizedDescription)")
            return nil
        }
    }
    
}
