//
//  PageView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 27/07/2026.
//

import UIKit
import SwiftUI
import KKit
import Model

protocol PageContentView: View {
    associatedtype Model: Hashable
    init(model: Model)
}

class PageContentViewController<Content: PageContentView>: UIHostingController<Content> {
    
    let model: Content.Model
    
    init(model: Content.Model) {
        self.model = model
        super.init(rootView: Content(model: model))
        view.backgroundColor = .clear
        view.insetsLayoutMarginsFromSafeArea = false
    }
    
    @MainActor @preconcurrency required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


protocol PageViewControllerDelegate: AnyObject {
    func updateOnScroll(_ index: Int)
}

class PageViewController<Content: PageContentView>: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    typealias Page = PageContentViewController<Content>
    private lazy var pageViewController: UIPageViewController = .init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    var models: [Content.Model]
    var currentModel: Content.Model?
    weak var delegate: (any PageViewControllerDelegate)?
    
    init(models: [Content.Model]) {
        self.models = models
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var internalScrollView: UIScrollView? {
        pageViewController.view.subviews.compactMap { $0 as? UIScrollView }.first
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view
            .fillSuperview()
        pageViewController.didMove(toParent: self)
        pageViewController.delegate = self
        pageViewController.dataSource = self
        self.pageViewController = pageViewController
        
        view.insetsLayoutMarginsFromSafeArea = false
        
        if #available(iOS 26.0, *), let scrollView = internalScrollView {
            scrollView.topEdgeEffect.style = .soft
        }
    }
    
    private func page(for model: Content.Model) -> PageContentViewController<Content> {
        .init(model: model)
    }
    
    func updatePages(models: [Content.Model], currentModel: Content.Model?) {
        
        guard self.models != models || self.currentModel != currentModel else { return }
        
        guard let currentModel else { return }
        
        pageViewController.setViewControllers([self.page(for: currentModel)], direction: .forward, animated: false)
        
        self.currentModel = currentModel
        self.models = models
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let pageController = viewController as? Page,
              let firstIndex = models.firstIndex(of: pageController.model) else { return nil }
        
        guard firstIndex > 0 else { return nil }
        
        let hostingController = page(for: models[firstIndex - 1])
        self.currentModel = models[firstIndex - 1]
        return hostingController
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let pageController = viewController as? Page,
              let firstIndex = models.firstIndex(of: pageController.model) else { return nil }
        
        guard firstIndex < models.count - 1 else { return nil }
        
        let hostingController = page(for: models[firstIndex + 1])
        self.currentModel = models[firstIndex + 1]
        return hostingController
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        let firstPendingViewController = pendingViewControllers.first as? Page
        
        guard let firstPendingViewController,
              let index = models.firstIndex(of: firstPendingViewController.model)
        else { return }
        
        print("(DEBUG) will transition to: \(index)")
//
//        delegate?.updateOnScroll(index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        print("(DEBUG) finished: \(finished) - completed: \(completed)")
        guard completed else {
            return
        }
        
        let firstPendingViewController = pageViewController.viewControllers?.first as? PageContentViewController<Content>
        
        guard let firstPendingViewController,
              currentModel != firstPendingViewController.model
        else { return }
        print("(DEBUG) firstPendingViewController: \(firstPendingViewController)")
        
        guard let index = models.firstIndex(of: firstPendingViewController.model) else { return }
        
        delegate?.updateOnScroll(index)
    }
}


struct PageView<Content: PageContentView>: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = PageViewController<Content>
    let models: [Content.Model]
    @Binding var current: Content.Model?
    
    init(models: [Content.Model], current: Binding<Content.Model?>) {
        self.models = models
        self._current = current
    }
    
    func makeUIViewController(context: Context) -> UIViewControllerType {
        let viewController = UIViewControllerType(models: models)
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        context.coordinator.models = models
        uiViewController.updatePages(models: models, currentModel: current)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator { model in
            self.current = model
        }
    }
    
    class Coordinator: PageViewControllerDelegate {
        
        var models: [Content.Model] = []
        let updateOnScroll: (Content.Model) -> Void
        
        init(updateOnScroll: @escaping (Content.Model) -> Void) {
            self.updateOnScroll = updateOnScroll
        }
        
        func updateOnScroll(_ index: Int) {
            guard index >= 0 && index <= self.models.count - 1 else { return }
            updateOnScroll(self.models[index])
        }
        
    }
    
}
