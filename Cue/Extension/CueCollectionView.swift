//
//  CueDataSource.swift
//  Cue
//
//  Created by Krishna Venkatramani on 20/01/2026.
//

import Foundation
import KKit
import UIKit
import SwiftUI
import VanorUI

//@resultBuilder
//struct CollectionSectionsBuilder {
//    
//    static func buildBlock(_ components: CueCollectionSection...) -> [CueCollectionSection] {
//        components
//    }
//    
//    static func buildEither(first component: CueCollectionSection) -> CueCollectionSection {
//        component
//    }
//    
//    static func buildEither(second component: CueCollectionSection) -> CueCollectionSection {
//        component
//    }
//}
//
//
//@resultBuilder
//struct CollectionItemForEach {
//    
//    ForEach
//}
//
//
//@resultBuilder
//struct CollectionSectionBuilder {
//    
//    static func buildBlock(_ components: DiffableCollectionCellProvider...) -> [DiffableCollectionCellProvider] {
//        components
//    }
//    
//    static func buildEither(first component: DiffableCollectionCellProvider) -> DiffableCollectionCellProvider {
//        component
//    }
//    
//    static func buildEither(second component: DiffableCollectionCellProvider) -> DiffableCollectionCellProvider {
//        component
//    }
//    
//    
//}
//
//
//
//struct CueCollectionSection {
//    let id: Int
//    @CollectionSectionBuilder
//    var cells: [DiffableCollectionCellProvider]
//    var sectionLayout: NSCollectionLayoutSection
//    var header: (any CollectionSupplementaryViewProvider)?
//    var footer: (any CollectionSupplementaryViewProvider)?
//    var decorationItem: (any CollectionDecorationViewProvider)?
//    
//    init(id: Int, sectionLayout: NSCollectionLayoutSection, header: (any CollectionSupplementaryViewProvider)? = nil, footer: (any CollectionSupplementaryViewProvider)? = nil, decorationItem: (any CollectionDecorationViewProvider)? = nil, @CollectionSectionBuilder cells: () -> [DiffableCollectionCellProvider]) {
//        self.id = id
//        self.cells = cells()
//        self.sectionLayout = sectionLayout
//        self.header = header
//        self.footer = footer
//        self.decorationItem = decorationItem
//    }
//    
//    var diffableCollectionSection: DiffableCollectionSection {
//        .init(id, cells: cells, header: header, footer: footer, decorationItem: decorationItem, sectionLayout: sectionLayout)
//    }
//}
//
//struct CollectionForEach {
//    
//    var cells: [DiffableCollectionCellProvider]
//    
//    init(data: [Identifiable])
//    
//}
//
struct CollectionView: UIViewRepresentable {
    
    private let section: [DiffableCollectionSection]
    private let completion: Callback?
    
    init(section: [DiffableCollectionSection], completion: Callback?) {
        self.section = section
        self.completion = completion
    }
    
    func makeUIView(context: Context) -> DiffableCollectionView {
        let collectionView = DiffableCollectionView(frame: .zero, collectionViewLayout: .init())
        collectionView.backgroundColor = .clear
        return collectionView
    }
    
    func updateUIView(_ uiView: DiffableCollectionView, context: Context) {
        uiView.reloadWithDynamicSection(sections: section, completion: completion)
    }
    
}
