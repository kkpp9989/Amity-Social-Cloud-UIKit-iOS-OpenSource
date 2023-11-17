//
//  AmityAllTypeMemberPickerFirstViewController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 4/11/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

public final class AmityAllTypeMemberPickerFirstViewController: AmityPageViewController {
        
    // MARK: - Child ViewController
    private var followingVC: AmityForwardMemberPickerViewController?
    private var followerVC: AmityForwardMemberPickerViewController?
    private var memberVC: AmityForwardAccountMemberPickerViewController?

    // MARK: - Component
    private var doneButton: UIBarButtonItem?
    
    // MARK: - Properties
    private var numberOfSelectedUseres: [AmitySelectMemberModel] = []
    private(set) var currentUsersInChat: [AmitySelectMemberModel] = []
        
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
        
        // Set color navigation bar by custom theme
        theme?.setBackgroundNavigationBar()
    }
    
    public static func make(currentUsers: [AmitySelectMemberModel]) -> AmityAllTypeMemberPickerFirstViewController {
        let vc = AmityAllTypeMemberPickerFirstViewController(nibName: AmityAllTypeMemberPickerFirstViewController.identifier,
                                                          bundle: AmityUIKitManager.bundle)
        vc.currentUsersInChat = currentUsers
        return vc
    }
    
    override func viewControllers(for pagerTabStripController: AmityPagerTabViewController) -> [UIViewController] {
        followingVC = AmityForwardMemberPickerViewController.make(pageTitle: "Following", users: currentUsersInChat, type: .following)
        followerVC = AmityForwardMemberPickerViewController.make(pageTitle: "Follower", users: currentUsersInChat, type: .followers)
        memberVC = AmityForwardAccountMemberPickerViewController.make(pageTitle: "Account", users: currentUsersInChat)
        
        followingVC?.selectUsersHandler = { [weak self] selectedUsers, newTitle in
            guard let strongSelf = self else { return }
            // Here you can access the selectedUsers from the child controller
            // Do whatever you need with the selectedUsers data
            strongSelf.numberOfSelectedUseres = selectedUsers
            strongSelf.doneButton?.isEnabled = !selectedUsers.isEmpty
            strongSelf.title = newTitle
        }
        followerVC?.selectUsersHandler = { [weak self] selectedUsers, newTitle in
            guard let strongSelf = self else { return }
            // Here you can access the selectedUsers from the child controller
            // Do whatever you need with the selectedUsers data
            strongSelf.numberOfSelectedUseres = selectedUsers
            strongSelf.doneButton?.isEnabled = !selectedUsers.isEmpty
            strongSelf.title = newTitle
        }
        memberVC?.selectUsersHandler = { [weak self] selectedUsers, newTitle in
            guard let strongSelf = self else { return }
            // Here you can access the selectedUsers from the child controller
            // Do whatever you need with the selectedUsers data
            strongSelf.numberOfSelectedUseres = selectedUsers
            strongSelf.doneButton?.isEnabled = !selectedUsers.isEmpty
            strongSelf.title = newTitle
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
        
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)
    }
    
    @objc func doneTap() {

        let vc = GroupChatCreatorSecondViewController.make(numberOfSelectedUseres)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func cancelTap() {
        dismiss(animated: true)
    }
    
    func viewControllerWillMove(newIndex: Int) {
        switch newIndex {
        case 0:
//            print("--------> [User] Go to tab acoount")
            memberVC?.setCurrentUsers(users: numberOfSelectedUseres)
        case 1:
//            print("--------> [User] Go to tab following")
            followingVC?.setCurrentUsers(users: numberOfSelectedUseres, isFromAnotherTab: true)
        case 2:
//            print("--------> [User] Go to tab follower")
            followerVC?.setCurrentUsers(users: numberOfSelectedUseres, isFromAnotherTab: true)
        default:
            break
        }
    }
}
