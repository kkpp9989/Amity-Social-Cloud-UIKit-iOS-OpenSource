//
//  AmityCommunityMemberSettingsViewController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 15/10/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit
import AmitySDK

public final class AmityCommunityMemberSettingsViewController: AmityPageViewController {
    
    private var screenViewModel: AmityCommunityMemberSettingsScreenViewModelType!
    
    // MARK: - Child ViewController
    private var memberVC: AmityCommunityMemberViewController?
    private var moderatorVC: AmityCommunityMemberViewController?
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    
    // MARK: - View lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = AmityLocalizedStringSet.CommunityMembreSetting.title.localizedString
        screenViewModel.delegate = self
        screenViewModel.action.getUserRoles()
        
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set color navigation bar by custom theme
        theme?.setBackgroundNavigationBar()
    }
    
    public static func make(community: AmityCommunity) -> AmityCommunityMemberSettingsViewController {
        let userRolesController: AmityCommunityUserRolesControllerProtocol = AmityCommunityUserRolesController(communityId: community.communityId)
        let viewModel: AmityCommunityMemberSettingsScreenViewModelType = AmityCommunityMemberSettingsScreenViewModel(community: AmityCommunityModel(object: community),
                                                                                                                 userRolesController: userRolesController)
        let vc = AmityCommunityMemberSettingsViewController(nibName: AmityCommunityMemberSettingsViewController.identifier,
                                                          bundle: AmityUIKitManager.bundle)
        
        vc.screenViewModel = viewModel
        return vc
    }
    
    override func viewControllers(for pagerTabStripController: AmityPagerTabViewController) -> [UIViewController] {
        memberVC = AmityCommunityMemberViewController.make(pageTitle: AmityLocalizedStringSet.CommunityMembreSetting.title.localizedString,
                                                         viewType: .member,
                                                         community: screenViewModel.dataSource.community)
        
        moderatorVC = AmityCommunityMemberViewController.make(pageTitle: AmityLocalizedStringSet.CommunityMembreSetting.moderatorTitle.localizedString,
                                                            viewType: .moderator,
                                                            community: screenViewModel.dataSource.community)
        return [memberVC!, moderatorVC!]
    }

    @objc private func addMemberTap() {
        guard let memberVC = memberVC else { return }
        let vc = AmityMemberPickerViewController.make(withCurrentUsers: memberVC.passMember())
        vc.selectUsersHandler = { storeUsers in
            memberVC.addMember(users: storeUsers)
        }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .overFullScreen
        present(nav, animated: true, completion: nil)
    }
}

extension AmityCommunityMemberSettingsViewController: AmityCommunityMemberSettingsScreenViewModelDelegate {
    func screenViewModelShouldShowAddButtonBarItem(status: Bool) {
        if status {
            let rightItem = UIBarButtonItem(image: AmityIconSet.iconAdd, style: .plain, target: self, action: #selector(addMemberTap))
            rightItem.tintColor = AmityColorSet.base
            navigationItem.rightBarButtonItem = rightItem
            navigationController?.reset()
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
}
