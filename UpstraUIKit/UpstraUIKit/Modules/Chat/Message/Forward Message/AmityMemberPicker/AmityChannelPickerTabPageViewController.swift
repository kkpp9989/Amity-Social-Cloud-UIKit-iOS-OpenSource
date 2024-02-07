//
//  AmityChannelPickerTabPageViewController.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 15/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

public final class AmityChannelPickerTabPageViewController: AmityPageViewController {
        
    public var selectUsersHandler: (([AmitySelectMemberModel]) -> Void)?

    // MARK: - Child ViewController
    private var recentVC: AmityForwatdChannelPickerViewController?
    private var followingVC: AmityForwardMemberPickerViewController?
    private var followerVC: AmityForwardMemberPickerViewController?
    private var groupChatVC: AmityForwatdChannelPickerViewController?
    
    // MARK: - Component
    private var doneButton: UIBarButtonItem?
    
    // MARK: - Properties
    private var numberOfSelectedUsers: [AmitySelectMemberModel] = []
    private var numberOfStoreUsers: [AmitySelectMemberModel] = []
    private var keyword: String = ""
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    
    // MARK: - View lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        delegate = self
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        theme?.clearNavigationBarSetting()
    }
    
    public static func make() -> AmityChannelPickerTabPageViewController {
        let vc = AmityChannelPickerTabPageViewController(nibName: AmityChannelPickerTabPageViewController.identifier,
                                                          bundle: AmityUIKitManager.bundle)
        return vc
    }
    
    override func viewControllers(for pagerTabStripController: AmityPagerTabViewController) -> [UIViewController] {
        recentVC = AmityForwatdChannelPickerViewController.make(pageTitle: AmityLocalizedStringSet.recent.localizedString, users: [], type: .recent)
        followingVC = AmityForwardMemberPickerViewController.make(pageTitle: AmityLocalizedStringSet.followingTitle.localizedString, users: [], type: .following)
        followerVC = AmityForwardMemberPickerViewController.make(pageTitle: AmityLocalizedStringSet.followersTitle.localizedString, users: [], type: .followers)
        groupChatVC = AmityForwatdChannelPickerViewController.make(pageTitle: AmityLocalizedStringSet.groups.localizedString, users: [], type: .group)
        
        recentVC?.selectUsersHandler = { [weak self] newSelectedUsers, storeUsers, title, keyword in
            guard let strongSelf = self else { return }
            // Here you can access the selectedUsers from the child controller
            // Do whatever you need with the selectedUsers data
            strongSelf.numberOfSelectedUsers = newSelectedUsers
            strongSelf.doneButton?.isEnabled = !newSelectedUsers.isEmpty
            strongSelf.numberOfStoreUsers = storeUsers
            strongSelf.keyword = keyword
        }
        followingVC?.selectUsersHandler = { [weak self] newSelectedUsers, storeUsers, title, keyword in
            guard let strongSelf = self else { return }
            // Here you can access the selectedUsers from the child controller
            // Do whatever you need with the selectedUsers data
            strongSelf.numberOfSelectedUsers = newSelectedUsers
            strongSelf.doneButton?.isEnabled = !newSelectedUsers.isEmpty
            strongSelf.numberOfStoreUsers = storeUsers
            strongSelf.keyword = keyword
        }
        followerVC?.selectUsersHandler = { [weak self] newSelectedUsers, storeUsers, title, keyword in
            guard let strongSelf = self else { return }
            // Here you can access the selectedUsers from the child controller
            // Do whatever you need with the selectedUsers data
            strongSelf.numberOfSelectedUsers = newSelectedUsers
            strongSelf.doneButton?.isEnabled = !newSelectedUsers.isEmpty
            strongSelf.numberOfStoreUsers = storeUsers
            strongSelf.keyword = keyword
        }
        groupChatVC?.selectUsersHandler = { [weak self] newSelectedUsers, storeUsers, title, keyword in
            guard let strongSelf = self else { return }
            // Here you can access the selectedUsers from the child controller
            // Do whatever you need with the selectedUsers data
            strongSelf.numberOfSelectedUsers = newSelectedUsers
            strongSelf.doneButton?.isEnabled = !newSelectedUsers.isEmpty
            strongSelf.numberOfStoreUsers = storeUsers
            strongSelf.keyword = keyword
        }
        return [recentVC!, followingVC!, followerVC!, groupChatVC!]
    }
    
    override func moveToViewController(at index: Int, animated: Bool = true) {
        super.moveToViewController(at: index, animated: animated)
        
        viewControllerWillMove(newIndex: index)
    }
    
    func setupNavigationBar() {
        title = "Forward to"
        titleFont = AmityFontSet.title

        doneButton = UIBarButtonItem(title: AmityLocalizedStringSet.General.forward.localizedString, style: .plain, target: self, action: #selector(doneTap))
        doneButton?.tintColor = AmityColorSet.primary
        // [Improvement] Add set font style to label of done button
        doneButton?.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .normal)
        doneButton?.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .disabled)
        doneButton?.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .selected)
        doneButton?.isEnabled = !numberOfSelectedUsers.isEmpty
        
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
        theme?.setBackgroundApp(index: 0)
    }
    
    @objc func doneTap() {
        dismiss(animated: true) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.selectUsersHandler?(strongSelf.numberOfStoreUsers)
        }
    }
    
    @objc func cancelTap() {
        dismiss(animated: true)
    }
    
    func viewControllerWillMove(newIndex: Int) {
        switch newIndex {
        case 0:
            recentVC?.setNewSelectedUsers(users: numberOfSelectedUsers, isFromAnotherTab: true, keyword: keyword)
            break
        case 1:
            followingVC?.setNewSelectedUsers(users: numberOfSelectedUsers, isFromAnotherTab: true, keyword: keyword)
            break
        case 2:
            followerVC?.setNewSelectedUsers(users: numberOfSelectedUsers, isFromAnotherTab: true, keyword: keyword)
            break
        case 3:
            groupChatVC?.setNewSelectedUsers(users: numberOfSelectedUsers, isFromAnotherTab: true, keyword: keyword)
            break
        default:
            break
        }
    }
}
