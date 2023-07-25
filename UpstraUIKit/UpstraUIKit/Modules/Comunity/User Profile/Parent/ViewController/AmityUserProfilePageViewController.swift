//
//  AmityUserProfileViewController.swift
//  AmityUIKit
//
//  Created by Nontapat Siengsanor on 29/9/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit
import AmitySDK

public class AmityUserProfilePageSettings {
    public init() { }
    public var shouldChatButtonHide: Bool = true
}

/// User settings
public final class AmityUserProfilePageViewController: AmityProfileViewController {
    
    // MARK: - Properties
    
    private var settings: AmityUserProfilePageSettings!
    private var header: AmityUserProfileHeaderViewController!
    private var bottom: AmityUserProfileBottomViewController!
    private let postButton: AmityFloatingButton = AmityFloatingButton()
    private var screenViewModel: AmityUserProfileScreenViewModelType!
    
    // MARK: - Custom Theme Properties [Additional]
    public var createPostItem: UIBarButtonItem = UIBarButtonItem()
    
    // MARK: - Initializer
    
    public static func make(withUserId userId: String, settings: AmityUserProfilePageSettings = AmityUserProfilePageSettings()) -> AmityUserProfilePageViewController {
        
        let viewModel: AmityUserProfileScreenViewModelType = AmityUserProfileScreenViewModel(userId: userId)
        
        let vc = AmityUserProfilePageViewController()
        vc.header = AmityUserProfileHeaderViewController.make(withUserId: userId, settings: settings)
        vc.bottom = AmityUserProfileBottomViewController.make(withUserId: userId)
        vc.screenViewModel = viewModel
        return vc
    }
    
    // MARK: - View's life cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        // [Custom for ONE Krungthai] Disable create post floating button
//        setupView()
        
        setupNavigationItem()
        setupViewModel()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setBackgroundColor(with: .white)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.reset()
    }
    
    // MARK: - Private functions
    
    private func setupView() {
        postButton.image = AmityIconSet.iconCreatePost
        postButton.add(to: view, position: .bottomRight)
        postButton.actionHandler = { [weak self] _ in
            guard let strongSelf = self else { return }
            AmityEventHandler.shared.createPostBeingPrepared(from: strongSelf, postTarget: .myFeed)
        }
        postButton.isHidden = !screenViewModel.isCurrentUser
    }
    
    private func setupNavigationItem() {
        /* Right items */
        var rightButtonItems: [UIBarButtonItem] = []
        
        // Option button
        let optionItem = UIBarButtonItem(image: AmityIconSet.iconOption, style: .plain, target: self, action: #selector(optionTap))
        optionItem.tintColor = AmityColorSet.base
        rightButtonItems.append(optionItem)
        
        // Create post button (with check moderator permission in official community)
        createPostItem = UIBarButtonItem(image: AmityIconSet.iconAdd, style: .plain, target: self, action: #selector(createPostTap))
        createPostItem.tintColor = AmityColorSet.base
        if screenViewModel.isCurrentUser { // Add create post item when profile is current user
            rightButtonItems.append(createPostItem)
        }
        
        // Add all button to navigation bar
        navigationItem.rightBarButtonItems = rightButtonItems
    }
    
    private func setupViewModel() {
        screenViewModel.delegate = self
    }
    
    // MARK: - AmityProfileDataSource
    override func headerViewController() -> UIViewController {
        return header
    }
    
    override func bottomViewController() -> UIViewController & AmityProfilePagerAwareProtocol {
        return bottom
    }
    
    override func minHeaderHeight() -> CGFloat {
        return topInset
    }
}

private extension AmityUserProfilePageViewController {
    @objc func optionTap() {
        let vc = AmityUserSettingsViewController.make(withUserId: screenViewModel.dataSource.userId)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func createPostTap() {
        AmityEventHandler.shared.createPostBeingPrepared(from: self, postTarget: .myFeed, menustyle: .pullDownMenuFromNavigationButton, selectItem: createPostItem)
    }
}

extension AmityUserProfilePageViewController: AmityUserProfileScreenViewModelDelegate {
    func screenViewModel(_ viewModel: AmityUserProfileScreenViewModelType, failure error: AmityError) {
        switch error {
        case .unknown:
            AmityHUD.show(.error(message: AmityLocalizedStringSet.HUD.somethingWentWrong.localizedString))
        default:
            break
        }
    }
}

extension AmityUserProfilePageViewController: UIPopoverPresentationControllerDelegate {
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none // Show the popover on iPhone devices as well
    }
}
