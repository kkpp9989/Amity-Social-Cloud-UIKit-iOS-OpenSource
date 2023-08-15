//
//  AmityNewsfeedViewController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 24/8/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit

/// A view controller for providing global feed with create post functionality.
public class AmityNewsfeedViewController: AmityViewController, IndicatorInfoProvider {
    
    func indicatorInfo(for pagerTabStripController: AmityPagerTabViewController) -> IndicatorInfo {
        return IndicatorInfo(title: pageTitle)
    }
    
    // MARK: - Properties
    var pageTitle: String?
    
    private let emptyView = AmityNewsfeedEmptyView()
    private var postTabHeaderView = AmityPostTabbarViewController.make()
    private var headerView = AmityMyCommunityPreviewViewController.make()
    private let createPostButton: AmityFloatingButton = AmityFloatingButton()
    private let feedViewController = AmityFeedViewController.make(feedType: .globalFeed)
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupFeedView()
        setupHeaderView()
        setupEmptyView()
        
        // [Custom for ONE Krungthai] Disable create post floating button
//        setupPostButton()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        headerView.retrieveCommunityList()
        postTabHeaderView.reloadView()
    }
    
    public static func make() -> AmityNewsfeedViewController {
        let vc = AmityNewsfeedViewController(nibName: nil, bundle: nil)
        return vc
    }
}

// MARK: - Setup view
private extension AmityNewsfeedViewController {
    
    private func setupFeedView() {
        addChild(viewController: feedViewController)
        feedViewController.dataDidUpdateHandler = { [weak self] itemCount in
            // [Custom For ONE Krungthai] [Fix-defect] Set post tab header view when update feed
            if itemCount > 1 {
                self?.feedViewController.postTabHeaderView = self?.postTabHeaderView
            } else {
                self?.feedViewController.postTabHeaderView = nil
            }
            
            self?.emptyView.setNeedsUpdateState()
        }
        
        feedViewController.pullRefreshHandler = { [weak self] in
            self?.headerView.retrieveCommunityList()
        }
    }
    
    private func setupHeaderView() {
        headerView.delegate = self
        postTabHeaderView.delegate = self
        
    }
    
    private func setupEmptyView() {
        emptyView.exploreHandler = { [weak self] in
            guard let parent = self?.parent as? AmityCommunityHomePageViewController else { return }
            // Switch to explore tap which is an index 1.
            parent.setCurrentIndex(1)
        }
        emptyView.createHandler = { [weak self] in
            let vc = AmityCommunityCreatorViewController.make()
            vc.delegate = self
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .overFullScreen
            self?.present(nav, animated: true, completion: nil)
        }
        feedViewController.emptyView = emptyView

    }
    
    private func setupPostButton() {
        // setup button
        createPostButton.add(to: view, position: .bottomRight)
        createPostButton.image = AmityIconSet.iconCreatePost
        createPostButton.actionHandler = { [weak self] _ in
            guard let strongSelf = self else { return }
            AmityEventHandler.shared.createPostBeingPrepared(from: strongSelf)
        }
    }
    
}

extension AmityNewsfeedViewController: AmityCommunityProfileEditorViewControllerDelegate {
    
    public func viewController(_ viewController: AmityCommunityProfileEditorViewController, didFinishCreateCommunity communityId: String) {
        AmityEventHandler.shared.communityDidTap(from: self, communityId: communityId)
    }
    
}

extension AmityNewsfeedViewController: AmityMyCommunityPreviewViewControllerDelegate {

    public func viewController(_ viewController: AmityMyCommunityPreviewViewController, didPerformAction action: AmityMyCommunityPreviewViewController.ActionType) {
        switch action {
        case .seeAll:
            let vc = AmityMyCommunityViewController.make()
            navigationController?.pushViewController(vc, animated: true)
        case .communityItem(let communityId):
            AmityEventHandler.shared.communityDidTap(from: self, communityId: communityId)
        }
    }

    public func viewController(_ viewController: AmityMyCommunityPreviewViewController, shouldShowMyCommunityPreview: Bool) {
        if shouldShowMyCommunityPreview {
            feedViewController.headerView = headerView
        } else {
            feedViewController.headerView = nil
        }
    }
}

extension AmityNewsfeedViewController: AmityPostTabbarViewControllerDelegate {
    public func viewController(_ viewController: AmityPostTabbarViewController) {
//        feedViewController.postTabHeaderView = postTabHeaderView
    }
    
    public func didTapPostButton(_ viewController: AmityPostTabbarViewController) {
        let postTargetVC = AmityPostTargetPickerViewController.make(postContentType: .post)
        let navPostTargetVC = UINavigationController(rootViewController: postTargetVC)
        navPostTargetVC.modalPresentationStyle = .fullScreen
        present(navPostTargetVC, animated: true, completion: nil)
    }
    
    public func didTapAvatarButton(_ viewController: AmityPostTabbarViewController) {
        AmityEventHandler.shared.userDidTap(from: self, userId: AmityUIKitManagerInternal.shared.currentUserId)
    }
}
    
