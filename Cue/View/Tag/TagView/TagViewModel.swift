//
//  TagViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 12/02/2026.
//

import Foundation
import Model

@Observable
class TagViewModel {
    
    var presentAddTagSheet: Bool = false
    var selectedTags: Set<TagModel> = .init()
    
    init(preSelectedTags: [TagModel]) {
        self.selectedTags = Set(preSelectedTags)
    }
    
    struct Section: Hashable, Identifiable {
        let initial: String
        var tags: [TagModel]
        
        var id: Int {
            hashValue
        }
    }
    
    var sectionedTags: [Section] = []
    
    func segmentedTags(tags: [CueTag]) {
        var tagsDict: [String: Section] = [:]
        for tag in tags {
            let initial = String(tag.name.prefix(1))
            
            if var existingTagsForInitial = tagsDict[initial]?.tags {
                existingTagsForInitial.append(.from(tag))
                tagsDict[initial]?.tags = existingTagsForInitial
            } else {
                tagsDict[initial] = .init(initial: initial, tags: [.from(tag)])
            }
        }
        
        sectionedTags = Array(tagsDict.keys.sorted().compactMap { tagsDict[$0] })
    }
    
    func selectTag(_ tag: TagModel) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    func tagsToDelete(_ indexSet: IndexSet, section: Int) -> [TagModel] {
        var tags: [TagModel] = []
        for index in indexSet {
            let key = sectionedTags[section].tags[index]
            tags.append(key)
        }
        return tags
    }
}
