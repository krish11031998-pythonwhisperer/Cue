//
//  EmojiSession.swift
//  Cue
//
//  Created by Krishna Venkatramani on 26/06/2026.
//

import FoundationModels
import VanorUI

@MainActor
class EmojiSession: CueLanguagareModelSession {

    @Generable
    struct Emoji {
        @Guide(description: "Emoji for sub-task")
        let emoji: String
    }
    
    convenience init() {
        let session = LanguageModelSession(model: .default, tools: [], instructions: """
            You are a emoji creating specialist. You will generate an emoji relevant to a sub-task title that will be prompted to you.
        
            You will just return an emoji as a string.
            For eg.
            if the prompt is "Pay Rent"
            you will return "💵"
            DO NOT USE MORE THAN ONE EMOJI
        """)
        self.init(session: session)
    }
    
    func generateEmoji(for prompt: String) async -> EmojiKit.Emoji {
        let emoji: Emoji? = await generate(for: prompt)
        guard let emojiChar = emoji?.emoji else {
            return EmojiKit.Emoji.all.randomElement()!
        }
        return .init(emojiChar)
    }
}
