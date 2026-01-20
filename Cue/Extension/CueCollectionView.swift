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
        return collectionView
    }
    
    func updateUIView(_ uiView: DiffableCollectionView, context: Context) {
        uiView.reloadWithDynamicSection(sections: section, completion: completion)
    }
    
}
//
//
//
//
//fileprivate struct TestView: ConfigurableView {
//    
//    struct Model: Hashable {
//        let index: Int
//    }
//    
//    let model: Model
//    
//    init(model: Model) {
//        self.model = model
//    }
//    
//    var body: some View {
//        Text("testCell \(model.index)")
//            .padding(.init(top: 12, leading: 16, bottom: 12, trailing: 16))
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .glassEffect(.regular, in: .roundedRect(cornerRadius: 12))
//        
//        ForEach(0..<10) { index in
//            
//        }
//    }
//    
//    static var viewName: String { "TestView" }
//}
//
//struct TestCollectionView: View {
//    
//    var body: some View {
//        CollectionView {
//            CueCollectionSection(id: 0, sectionLayout: .singleColumnLayout(width: .fractionalWidth(1), height: .estimated(54), insets: .section(.init(top: 8, leading: 10, bottom: 0, trailing: 10)))) {
////                CollectionSectionBuilder { index in
//                    DiffableCollectionItem<TestView>(.init(index: 0))
//                    DiffableCollectionItem<TestView>(.init(index: 1))
//                    DiffableCollectionItem<TestView>(.init(index: 2))
//                    DiffableCollectionItem<TestView>(.init(index: 3))
//                    DiffableCollectionItem<TestView>(.init(index: 4))
//                    DiffableCollectionItem<TestView>(.init(index: 5))
////                }
//            }
//        }
//    }
//    
//}
//
//
//#Preview {
//    TestCollectionView()
//}
