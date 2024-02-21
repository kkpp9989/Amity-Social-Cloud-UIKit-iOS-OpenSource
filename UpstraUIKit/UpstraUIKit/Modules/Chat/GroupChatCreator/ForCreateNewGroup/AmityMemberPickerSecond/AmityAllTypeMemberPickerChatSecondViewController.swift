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
    
    // MARK: - Component
    private var doneButton: UIBarButtonItem?
    
    // MARK: - Properties
    private var numberOfSelectedUsers: [AmitySelectMemberModel] = []
    private var numberOfStoreUsers: [AmitySelectMemberModel] = []
    private(set) var currentUsersInChat: [AmitySelectMemberModel] = []
    private var screenViewModel: AmityMemberPickerChatScreenViewModelType!
    private var displayName: String = ""
    private var keyword: String = ""

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
        theme?.clearNavigationBarSetting()
    }
    
    public static func make(withCurrentUsers users: [AmitySelectMemberModel] = [],
                            liveChannelBuilder: AmityCommunityChannelBuilder? = nil,
                            displayName: String = "") -> AmityAllTypeMemberPickerChatSecondViewController {
        let viewModel: AmityMemberPickerChatScreenViewModelType = AmityMemberPickerChatScreenViewModel(amityUserUpdateBuilder: liveChannelBuilder ?? AmityCommunityChannelBuilder())
        viewModel.setCurrentUsers(users: users)
        let vc = AmityAllTypeMemberPickerChatSecondViewController(nibName: AmityAllTypeMemberPickerChatSecondViewController.identifier, bundle: AmityUIKitManager.bundle)
        vc.screenViewModel = viewModel
        vc.displayName = displayName
        vc.currentUsersInChat = users
        return vc
    }
    
    override func viewControllers(for pagerTabStripController: AmityPagerTabViewController) -> [UIViewController] {
        followingVC = AmityForwardMemberPickerViewController.make(pageTitle: AmityLocalizedStringSet.followingTitle.localizedString, users: currentUsersInChat, type: .following)
        followerVC = AmityForwardMemberPickerViewController.make(pageTitle: AmityLocalizedStringSet.followersTitle.localizedString, users: currentUsersInChat, type: .followers)
        memberVC = AmityForwardAccountMemberPickerViewController.make(pageTitle: AmityLocalizedStringSet.accounts.localizedString, users: currentUsersInChat)
        
        followingVC?.selectUsersHandler = { [weak self] newSelectedUsers, storeUsers, title, keyword in
            guard let strongSelf = self else { return }
            // Here you can access the selectedUsers from the child controller
            // Do whatever you need with the selectedUsers data
            strongSelf.numberOfSelectedUsers = newSelectedUsers
            strongSelf.doneButton?.isEnabled = !newSelectedUsers.isEmpty
            strongSelf.numberOfStoreUsers = storeUsers
            strongSelf.title = title
            strongSelf.keyword = keyword
        }
        followerVC?.selectUsersHandler = { [weak self] newSelectedUsers, storeUsers, title, keyword in
            guard let strongSelf = self else { return }
            // Here you can access the selectedUsers from the child controller
            // Do whatever you need with the selectedUsers data
            strongSelf.numberOfSelectedUsers = newSelectedUsers
            strongSelf.doneButton?.isEnabled = !newSelectedUsers.isEmpty
            strongSelf.numberOfStoreUsers = storeUsers
            strongSelf.title = title
            strongSelf.keyword = keyword
        }
        memberVC?.selectUsersHandler = { [weak self] newSelectedUsers, storeUsers, title, keyword in
            guard let strongSelf = self else { return }
            // Here you can access the selectedUsers from the child controller
            // Do whatever you need with the selectedUsers data
            strongSelf.numberOfSelectedUsers = newSelectedUsers
            strongSelf.doneButton?.isEnabled = !newSelectedUsers.isEmpty
            strongSelf.numberOfStoreUsers = storeUsers
            strongSelf.title = title
            strongSelf.keyword = keyword
        }
        return [memberVC!, followingVC!, followerVC!]
    }
    
    override func moveToViewController(at index: Int, animated: Bool = true) {
        super.moveToViewController(at: index, animated: animated)
        
        viewControllerWillMove(newIndex: index)
    }
    
    func setupNavigationBar() {
        titleFont = AmityFontSet.title
        title = AmityLocalizedStringSet.selectMemberListTitle.localizedString

        doneButton = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(doneTap))
        doneButton?.tintColor = AmityColorSet.primary
        doneButton?.isEnabled = !numberOfSelectedUsers.isEmpty
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
        
//        navigationItem.leftBarButtonItem = cancelButton // Disable set cancel button because this viewcontroller was pushed from first viewcontroller
        navigationItem.rightBarButtonItem = doneButton
        
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)
        theme?.setBackgroundApp(index: 0)
    }
    
    @objc func doneTap() {
        screenViewModel.action.createChannel(users: numberOfStoreUsers, displayName: displayName)
    }
    
    @objc func cancelTap() {
        dismiss(animated: true)
    }
    
    func viewControllerWillMove(newIndex: Int) {
        switch newIndex {
        case 0:
            memberVC?.setNewSelectedUsers(users: numberOfSelectedUsers, isFromAnotherTab: true, keyword: keyword)
            memberVC?.lastSearchKeyword = keyword
        case 1:
            followingVC?.setNewSelectedUsers(users: numberOfSelectedUsers, isFromAnotherTab: true, keyword: keyword)
            followingVC?.lastSearchKeyword = keyword
        case 2:
            followerVC?.setNewSelectedUsers(users: numberOfSelectedUsers, isFromAnotherTab: true, keyword: keyword)
            followerVC?.lastSearchKeyword = keyword
        default:
            break
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
