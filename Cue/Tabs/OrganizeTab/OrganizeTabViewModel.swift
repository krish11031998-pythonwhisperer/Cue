//
//  OrganizeTabViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 12/02/2026.
//

import Model
import Foundation
import VanorUI
import SwiftUI
import CoreData

@Observable
class OrganizeTabViewModel {
    enum Presentation: Identifiable {
        case tags
        case reminder(ReminderModel)
        
        var id: Int {
            switch self {
            case .tags:
                return 0
            case .reminder:
                return 1
            }
        }
    }
    
    enum Mode: Hashable{
        case all
        case tag([String])
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .all:
                hasher.combine("all")
            case .tag(let array):
                hasher.combine(array)
            }
        }
        
        static func == (lhs: Mode, rhs: Mode) -> Bool {
            switch (lhs, rhs) {
            case (.all, .all):
                return true
            case (.tag(let arrayOne), .tag(let arrayTwo)):
                return arrayOne == arrayTwo
            default:
                return false
            }
        }
    }
    
    struct CellViewModel: Hashable, Identifiable {
        let reminder: ReminderModel
        let cellViewModel: ReminderView.Model
        
        var id: Int { reminder.hashValue }
    }
    
    @ObservationIgnored
    var selectedTag: Set<TagModel> = .init()
    var reminders: [CellViewModel] = []
    var mode: Mode = .all
    var selectedPresentation: Presentation? = nil
    var tags: [TagModel] = []
    
    @MainActor
    func updateReminder(with backgroundContext: NSManagedObjectContext) async {
        let tags = Array(selectedTag)
        let reminders: [CellViewModel]
        let type: OrganizeFilterController.FetchType
        if tags.isEmpty {
            type = .all
        } else {
            type = .tags(tags.map(\.name))
        }
        reminders = await OrganizeFilterController.shared.fetchReminders(with: backgroundContext, type: type) { reminder in
            let icon: VanorUI.Icon
            if let symbol = reminder.icon.symbol {
                icon = .symbol(.init(rawValue: symbol))
            } else if let emoji = reminder.icon.emoji {
                icon = .emoji(.init(emoji))
            } else {
                icon = .symbol(.circle)
            }
            let cellViewModel = ReminderView.Model(title: reminder.title,
                                                   icon: icon,
                                                   theme: Color.proSky,
                                                   time: reminder.date,
                                                   state: .display,
                                                   tags: reminder.tags.map{ .init(name: $0.name, color: $0.color) },
                                                   logReminder: nil, deleteReminder: nil)
            return .init(reminder: reminder, cellViewModel: cellViewModel)
        }
        
        guard !Task.isCancelled else { return }
        self.reminders = reminders
    }
    
    var tagChipView: [TagChipView.Model] {
        let allCell = TagChipView.Model(name: "All", color: Color.proOrange.baseColor, viewType: .button(mode == .all, {
            self.selectedTag.removeAll()
            self.mode = .all
        }))
        let tagCells: [TagChipView.Model] = self.tags.map { tag in
            let selected = self.selectedTag.contains(tag)
            let viewType = TagChipView.ViewType.button(selected, { [weak self] in
                guard let self else { return }
                if self.selectedTag.contains(tag) {
                    self.selectedTag.remove(tag)
                } else {
                    self.selectedTag.insert(tag)
                }
                self.mode = .tag(self.selectedTag.map(\.name))
            })
            return .init(name: tag.name, color: tag.color, viewType: viewType)
        }
        
        return [allCell] + tagCells
    }
    
    func tagModel(_ tags: [CueTag]) {
        self.tags = tags.map { .from($0) }
    }
    
//    func presentReminder(for cellViewModel: ReminderView.Model) {
//        let reminder = viewModelsToReminder[cellViewModel]
//        guard let reminder else { return }
//        self.selectedPresentation = .reminder(reminder)
//    }
}
