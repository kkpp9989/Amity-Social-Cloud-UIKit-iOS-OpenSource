//
//  AmityCommunityProfilePageViewController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 20/4/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

import UIKit

/// A view controller for providing community profile and community feed.
public final class AmityCommunityProfilePageViewController: AmityProfileViewController {
    
    static var newCreatedCommunityIds = Set<String>()
    
    // MARK: - Properties
    private var header: AmityCommunityProfileHeaderViewController!
    private var bottom: AmityCommunityFeedViewController!
    private var postButton: AmityFloatingButton = AmityFloatingButton()
    
    private var screenViewModel: AmityCommunityProfileScreenViewModelType!
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    public var createPostItem: UIBarButtonItem = UIBarButtonItem()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)
        
        setupFeed()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupViewModel()
        
        // Set color navigation bar by custom theme
        theme?.setBackgroundNavigationBar()
        
        // [Custom for ONE Krungthai] Disable create post floating button
//        setupPostButton()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showCommunitySettingModal()
    }
    
    public static func make(
        withCommunityId communityId: String
    ) -> AmityCommunityProfilePageViewController {
        
        let communityRepositoryManager = AmityCommunityRepositoryManager(communityId: communityId)
        let viewModel = AmityCommunityProfileScreenViewModel(
            communityId: communityId,
            communityRepositoryManager: communityRepositoryManager
        )
        let vc = AmityCommunityProfilePageViewController()
        vc.screenViewModel = viewModel
        vc.header = AmityCommunityProfileHeaderViewController.make(rootViewController: vc, viewModel: viewModel)
        vc.bottom = AmityCommunityFeedViewController.make(communityId: communityId)
        return vc
        
    }
    
    override func headerViewController() -> UIViewController {
        return header
    }
    
    override func bottomViewController() -> UIViewController & AmityProfilePagerAwareProtocol {
        return bottom
    }
    
    override func minHeaderHeight() -> CGFloat {
        return topInset
    }
    
    public override func didTapLeftBarButton() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Setup ViewModel
    private func setupViewModel() {
        screenViewModel.delegate = self
        screenViewModel.action.retriveCommunity()
    }
    
    // MARK: - Setup views
    private func setupFeed() {
        header.didUpdatePostBanner = { [weak self] in
            self?.bottom.handleRefreshFeed()
        }
        
        bottom.dataDidUpdateHandler = { [weak self] in
            self?.header.updatePostsCount()
        }
    }
    private func setupPostButton() {
        postButton.image = AmityIconSet.iconCreatePost
        postButton.add(to: view, position: .bottomRight)
        postButton.actionHandler = { [weak self] button in
            self?.postAction()
        }
    }
    
    // [Custom for ONE Krungthai] Modify function for add create post button with check moderator permission of official community
    private func setupNavigationItemOption(show isJoined: Bool) {
        /* Check user is join community before show button */
        if isJoined {
            /* Right items */
            var rightButtonItems: [UIBarButtonItem] = []
            
            // Option button
            let optionItem = UIBarButtonItem(image: AmityIconSet.iconOption, style: .plain, target: self, action: #selector(optionTap))
            optionItem.tintColor = AmityColorSet.base
            rightButtonItems.append(optionItem)
            
            // Create post button (with check moderator permission in official community)
            createPostItem = UIBarButtonItem(image: AmityIconSet.iconAdd, style: .plain, target: self, action: #selector(createPostTap))
            createPostItem.tintColor = AmityColorSet.base
            let isModeratorUserInOfficialCommunity = AmityMemberCommunityUtilities.isModeratorUserInCommunity(withUserId: AmityUIKitManagerInternal.shared.currentUserId, communityId: screenViewModel.communityId)
            let isOfficial = self.screenViewModel.community?.isOfficial ?? false
            
            if isOfficial { // Case : Official community
                if isModeratorUserInOfficialCommunity { // Case : Moderator user in official community
                    rightButtonItems.append(createPostItem)
                }
            } else { // Case : Not official community
                rightButtonItems.append(createPostItem)
            }
            
            // Add all button to navigation bar
            navigationItem.rightBarButtonItems = rightButtonItems
        }
    }
    
    private func showCommunitySettingModal() {
        if AmityCommunityProfilePageViewController.newCreatedCommunityIds.contains(screenViewModel.dataSource.communityId) {
            let firstAction = AmityDefaultModalModel.Action(title: AmityLocalizedStringSet.communitySettings,
                                                          textColor: AmityColorSet.baseInverse,
                                                          backgroundColor: AmityColorSet.primary)
            let secondAction = AmityDefaultModalModel.Action(title: AmityLocalizedStringSet.skipForNow,
                                                           textColor: AmityColorSet.primary,
                                                           font: AmityFontSet.body,
                                                           backgroundColor: .clear)

            let communitySettingsModel = AmityDefaultModalModel(image: AmityIconSet.iconMagicWand,
                                                              title: AmityLocalizedStringSet.Modal.communitySettingsTitle,
                                                              description: AmityLocalizedStringSet.Modal.communitySettingsDesc,
                                                              firstAction: firstAction,
                                                              secondAction: secondAction,
                                                              layout: .vertical)
            let communitySettingsModalView = AmityDefaultModalView.make(content: communitySettingsModel)
            communitySettingsModalView.firstActionHandler = {
                AmityHUD.hide { [weak self] in
                    self?.screenViewModel.action.route(.settings)
                }
            }
            
            communitySettingsModalView.secondActionHandler = {
                AmityHUD.hide()
            }
        
            AmityHUD.show(.custom(view: communitySettingsModalView))
            AmityCommunityProfilePageViewController.newCreatedCommunityIds.remove(screenViewModel.dataSource.communityId)
        }
    }
    
}

// MARK: - Action
private extension AmityCommunityProfilePageViewController {
    @objc func optionTap() {
        screenViewModel.action.route(.settings)
    }
    
    @objc func createPostTap() {
        // Go to current action
        postAction()
    }
    
    func postAction() {
        screenViewModel.action.route(.post)
    }
}

extension AmityCommunityProfilePageViewController: AmityCommunityProfileScreenViewModelDelegate {
    
    func screenViewModelDidGetCommunity(with community: AmityCommunityModel) {
        postButton.isHidden = !community.isJoined
        header.updateView()
        setupNavigationItemOption(show: community.isJoined)
        AmityHUD.hide()
    }
    
    func screenViewModelFailure() {
        AmityHUD.hide {
            AmityHUD.show(.error(message: AmityLocalizedStringSet.HUD.somethingWentWrong.localizedString))
        }
    }
    
    func screenViewModelRoute(_ viewModel: AmityCommunityProfileScreenViewModel, route: AmityCommunityProfileRoute) {
        guard let community = viewModel.community else { return }
        switch route {
        case .post:
            // [Custom for ONE Krungthai] Change setting of create post menu | [Warning] Must to run setupNavigationItemOption() before this process because of permission
            AmityEventHandler.shared.createPostBeingPrepared(from: self, postTarget: .community(object: community.object), menustyle: .pullDownMenuFromNavigationButton, selectItem: createPostItem)
            // [Original]
//            AmityEventHandler.shared.createPostBeingPrepared(from: self, postTarget: .community(object: community.object))
        case .member:
            let vc = AmityCommunityMemberSettingsViewController.make(community: community.object)
            navigationController?.pushViewController(vc, animated: true)
        case .settings:
            let vc = AmityCommunitySettingsViewController.make(communityId: community.communityId)
            navigationController?.pushViewController(vc, animated: true)
        case .editProfile:
            let vc = AmityCommunityEditorViewController.make(withCommunityId: community.communityId)
            vc.delegate = self
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        case .pendingPosts:
            let vc = AmityPendingPostsViewController.make(communityId: viewModel.communityId)
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    
}

extension AmityCommunityProfilePageViewController: AmityRefreshable {
    
    func handleRefreshing() {
        screenViewModel.action.retriveCommunity()
    }

}

extension AmityCommunityProfilePageViewController: AmityCommunityProfileEditorViewControllerDelegate {

    public func viewController(_ viewController: AmityCommunityProfileEditorViewController, didFinishCreateCommunity communityId: String) {
        AmityEventHandler.shared.communityDidTap(from: self, communityId: communityId)
    }

    public func viewController(_ viewController: AmityCommunityProfileEditorViewController, didFailWithNoPermission: Bool) {
        navigationController?.popToRootViewController(animated: true)
    }

}

extension AmityCommunityProfilePageViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none // Show the popover on iPhone devices as well
    }
}
