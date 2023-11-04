//
//  AmityAllTypeMemberPickerChatSecondViewController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 4/11/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityAllTypeMemberPickerChatSecondViewController: AmityPageViewController {
    
    // MARK: - Child ViewController
    private var followingVC: AmityForwardMemberPickerViewController?
    private var followerVC: AmityForwardMemberPickerViewController?
    private var memberVC: AmityForwardAccountMemberPickerViewController?
    
    private var doneButton: UIBarButtonItem?
    
    private var numberOfSelectedUseres: [AmitySelectMemberModel] = []
        
    private var screenViewModel: AmityMemberPickerChatScreenViewModelType!
    private var displayName: String = ""

    public var tapCreateButton: ((String, String) -> Void)?

    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    
    // MARK: - View lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        screenViewModel.delegate = self
        delegate = self
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set color navigation bar by custom theme
        theme?.setBackgroundNavigationBar()
    }
    
    public static func make(withCurrentUsers users: [AmitySelectMemberModel] = [],
                            liveChannelBuilder: AmityLiveChannelBuilder? = nil,
                            displayName: String = "") -> AmityAllTypeMemberPickerChatSecondViewController {
        let viewModel: AmityMemberPickerChatScreenViewModelType = AmityMemberPickerChatScreenViewModel(amityUserUpdateBuilder: liveChannelBuilder ?? AmityLiveChannelBuilder())
        viewModel.setCurrentUsers(users: users)
        let vc = AmityAllTypeMemberPickerChatSecondViewController(nibName: AmityAllTypeMemberPickerChatSecondViewController.identifier, bundle: AmityUIKitManager.bundle)
        vc.screenViewModel = viewModel
        vc.displayName = displayName
        return vc
    }
    
    override func viewControllers(for pagerTabStripController: AmityPagerTabViewController) -> [UIViewController] {
        followingVC = AmityForwardMemberPickerViewController.make(pageTitle: "Following", users: [], type: .following)
        followerVC = AmityForwardMemberPickerViewController.make(pageTitle: "Follower", users: [], type: .followers)
        memberVC = AmityForwardAccountMemberPickerViewController.make(pageTitle: "Account", users: [])
        
        followingVC?.selectUsersHandler = { [weak self] selectedUsers in
            guard let strongSelf = self else { return }
            // Here you can access the selectedUsers from the child controller
            // Do whatever you need with the selectedUsers data
            strongSelf.numberOfSelectedUseres = selectedUsers
            strongSelf.doneButton?.isEnabled = !selectedUsers.isEmpty
        }
        followerVC?.selectUsersHandler = { [weak self] selectedUsers in
            guard let strongSelf = self else { return }
            // Here you can access the selectedUsers from the child controller
            // Do whatever you need with the selectedUsers data
            strongSelf.numberOfSelectedUseres = selectedUsers
            strongSelf.doneButton?.isEnabled = !selectedUsers.isEmpty
        }
        memberVC?.selectUsersHandler = { [weak self] selectedUsers in
            guard let strongSelf = self else { return }
            // Here you can access the selectedUsers from the child controller
            // Do whatever you need with the selectedUsers data
            strongSelf.numberOfSelectedUseres = selectedUsers
            strongSelf.doneButton?.isEnabled = !selectedUsers.isEmpty
        }
        return [memberVC!, followingVC!, followerVC!]
    }
    
    override func moveToViewController(at index: Int, animated: Bool = true) {
        super.moveToViewController(at: index, animated: animated)
        
        viewControllerWillMove()
    }
    
    func setupNavigationBar() {
        titleFont = AmityFontSet.title
        title = AmityLocalizedStringSet.selectMemberListTitle.localizedString

        doneButton = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(doneTap))
        doneButton?.tintColor = AmityColorSet.primary
        doneButton?.isEnabled = !numberOfSelectedUseres.isEmpty
        // [Improvement] Add set font style to label of done button
        doneButton?.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .normal)
        doneButton?.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .disabled)
        doneButton?.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .selected)
        
        let cancelButton = UIBarButtonItem(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .plain, target: self, action: #selector(cancelTap))
        cancelButton.tintColor = AmityColorSet.base
        // [Improvement] Add set font style to label of cancel button
        cancelButton.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .normal)
        cancelButton.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .disabled)
        cancelButton.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .selected)
        
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = doneButton
        
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)
    }
    
    @objc func doneTap() {
        screenViewModel.action.createChannel(users: numberOfSelectedUseres, displayName: displayName)
    }
    
    @objc func cancelTap() {
        dismiss(animated: true)
    }
    
    func viewControllerWillMove() {
        if currentIndex == 1 {
            memberVC?.setCurrentUsers(users: numberOfSelectedUseres)
        } else if currentIndex == 2 {
            followingVC?.setCurrentUsers(users: numberOfSelectedUseres)
        } else {
            followerVC?.setCurrentUsers(users: numberOfSelectedUseres)
        }
    }
}

extension AmityAllTypeMemberPickerChatSecondViewController: AmityMemberPickerChatScreenViewModelDelegate {
    func screenViewModelDidCreateCommunity(_ viewModel: AmityMemberPickerChatScreenViewModelType, channelId: String, subChannelId: String) {
        dismiss(animated: true) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.tapCreateButton?(channelId, subChannelId)
        }
    }
    
    func screenViewModelDidFetchUser() {
    }
    
    func screenViewModelDidSearchUser() {
    }
    
    func screenViewModelCanDone(enable: Bool) {
        doneButton?.isEnabled = enable
    }
    
    func screenViewModelDidSelectUser(title: String, isEmpty: Bool) {
    }
    
    func screenViewModelLoadingState(for state: AmityLoadingState) {
    }
}
