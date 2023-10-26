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
    
    private var doneButton: UIBarButtonItem?
    
    private var numberOfSelectedUseres: [AmitySelectMemberModel] = []
    
    // MARK: - View lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        delegate = self
    }
    
    public static func make() -> AmityChannelPickerTabPageViewController {
        let vc = AmityChannelPickerTabPageViewController(nibName: AmityChannelPickerTabPageViewController.identifier,
                                                          bundle: AmityUIKitManager.bundle)
        return vc
    }
    
    override func viewControllers(for pagerTabStripController: AmityPagerTabViewController) -> [UIViewController] {
        recentVC = AmityForwatdChannelPickerViewController.make(pageTitle: "Recent", users: [], type: .recent)
        followingVC = AmityForwardMemberPickerViewController.make(pageTitle: "Following", users: [], type: .following)
        followerVC = AmityForwardMemberPickerViewController.make(pageTitle: "Follower", users: [], type: .followers)
        groupChatVC = AmityForwatdChannelPickerViewController.make(pageTitle: "Group", users: [], type: .group)
        
        recentVC?.selectUsersHandler = { [weak self] selectedUsers in
            guard let strongSelf = self else { return }
            // Here you can access the selectedUsers from the child controller
            // Do whatever you need with the selectedUsers data
            strongSelf.numberOfSelectedUseres = selectedUsers
            strongSelf.doneButton?.isEnabled = !selectedUsers.isEmpty
        }
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
        groupChatVC?.selectUsersHandler = { [weak self] selectedUsers in
            guard let strongSelf = self else { return }
            // Here you can access the selectedUsers from the child controller
            // Do whatever you need with the selectedUsers data
            strongSelf.numberOfSelectedUseres = selectedUsers
            strongSelf.doneButton?.isEnabled = !selectedUsers.isEmpty
        }
        return [recentVC!, followingVC!, followerVC!, groupChatVC!]
    }
    
    func setupNavigationBar() {
        title = "Forward to"
        titleFont = AmityFontSet.title

        doneButton = UIBarButtonItem(title: AmityLocalizedStringSet.General.next.localizedString, style: .plain, target: self, action: #selector(doneTap))
        doneButton?.tintColor = AmityColorSet.primary
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
    }
    
    @objc func doneTap() {
        dismiss(animated: true) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.selectUsersHandler?(strongSelf.numberOfSelectedUseres)
        }
    }
    
    @objc func cancelTap() {
        dismiss(animated: true)
    }
}
