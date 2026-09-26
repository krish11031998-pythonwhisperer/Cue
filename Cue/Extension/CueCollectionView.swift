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
        collectionView.topEdgeEffect.style = .soft
        return collectionView
    }
    
    func updateUIView(_ uiView: DiffableCollectionView, context: Context) {
        uiView.reloadWithDynamicSection(sections: section, completion: completion)
    }
}

struct TabCollectionViewController: UIViewControllerRepresentable {
    
    private let section: [DiffableCollectionSection]
    private let additionalContentInsets: UIEdgeInsets
    private let completion: Callback?
    
    init(section: [DiffableCollectionSection], additionalContentInsets: UIEdgeInsets, completion: Callback?) {
        self.section = section
        self.additionalContentInsets = additionalContentInsets
        self.completion = completion
    }
    
    func makeUIViewController(context: Context) -> CollectionViewController {
        CollectionViewController()
    }
    
    func updateUIViewController(_ uiViewController: CollectionViewController, context: Context) {
        uiViewController.reload(with: section, completion: completion)
        uiViewController.applyAdditionalContentInsets(additionalContentInsets)
    }
}

class CollectionViewController: UIViewController {
    
    private lazy var collectionView: DiffableCollectionView = .init()
    private var sections: [DiffableCollectionSection] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(collectionView)
        collectionView
            .fillSuperview()
        collectionView.backgroundColor = .clear
        collectionView.topEdgeEffect.style = .soft
        setupNavigationController()
    }
    
    private func setupNavigationController() {
        guard let navigationController else { return }
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.navigationBar.largeTitleTextAttributes = [.font: UIFont.bitcountMedium(style: .largeTitle)]
    }
    
    func reload(with sections: [DiffableCollectionSection], completion: Callback?) {
        guard self.sections != sections else { return }
        self.sections = sections
        self.collectionView.reloadWithDynamicSection(sections: sections, completion: completion)
    }
    
    func applyAdditionalContentInsets(_ contentInsets: UIEdgeInsets) {
        self.additionalSafeAreaInsets = contentInsets
    }
}
