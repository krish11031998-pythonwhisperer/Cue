//
//  EmojiTool.swift
//  Cue
//
//  Created by Krishna Venkatramani on 20/06/2026.
//

import FoundationModels
import VanorUI

@Generable
struct EmojisForCategory {
    let emojis: String
}

struct EmojiTool: Tool {
    
    var name: String = "EmojiTool"
    var description: String = "A tool to generate emoji for described activity"
    
    @Generable
    struct Arguments {
        @Guide(description: "Activity mentioned in the prompt")
        let activity: String
    }
    
    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        print("(DEBUG) category recognized: \(arguments.activity)")
        return GeneratedContent(properties: ["emojis": EmojiCategory.search(query: arguments.activity).emojis.map(\.char)])
    }
}
