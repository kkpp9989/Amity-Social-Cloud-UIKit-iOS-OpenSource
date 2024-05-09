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
    private let scrollUpButton: AmityFloatingButton = AmityFloatingButton()
    private var screenViewModel: AmityUserProfileScreenViewModelType!
    
    // MARK: - Custom Theme Properties [Additional]
    public var rightBarButtons: UIBarButtonItem = UIBarButtonItem()
    
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
        setupScrollUpButton()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		navigationController?.isNavigationBarHidden = false
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
    
    private func setupScrollUpButton() {
        // setup button
        scrollUpButton.isHidden = true
        scrollUpButton.add(to: view, position: .bottomRight)
        scrollUpButton.image = AmityIconSet.iconScrollUp
        scrollUpButton.actionHandler = { [weak self] _ in
            guard let strongSelf = self else { return }
            NotificationCenter.default.post(name: Notification.Name("ScrollToTop"), object: nil)
        }
        
        bottom.timelineVC?.hideScrollUpButtonHandler = { [weak self] in
            UIView.animate(withDuration: 0.5, animations: {
                self?.scrollUpButton.alpha = 0.0
            }) { _ in
                self?.scrollUpButton.isHidden = true
            }
        }
        
        bottom.timelineVC?.showScrollUpButtonHandler = { [weak self] in
            UIView.animate(withDuration: 0.5, animations: {
                self?.scrollUpButton.alpha = 1.0
            }) { _ in
                self?.scrollUpButton.isHidden = false
            }
        }
    }
    
    private func setupNavigationItem() {
        /* Right items */
        // [Improvement] Change set button solution to use custom stack view
        var rightButtonItems: [UIButton] = []
        
        // Create post button
        let createPostButton: UIButton = UIButton.init(type: .custom)
        createPostButton.setImage(AmityIconSet.iconAddNavigationBar?.withRenderingMode(.alwaysOriginal), for: .normal)
        createPostButton.addTarget(self, action: #selector(createPostTap), for: .touchUpInside)
        createPostButton.frame = CGRect(x: 0, y: 0, width: ONEKrungthaiCustomTheme.defaultIconBarItemWidth, height: ONEKrungthaiCustomTheme.defaultIconBarItemHeight)
        rightButtonItems.append(createPostButton)
        
        // Option Button
        let optionButton: UIButton = UIButton.init(type: .custom)
        optionButton.setImage(AmityIconSet.iconOptionNavigationBar?.withRenderingMode(.alwaysOriginal), for: .normal)
        optionButton.addTarget(self, action: #selector(optionTap), for: .touchUpInside)
        optionButton.frame = CGRect(x: 0, y: 0, width: ONEKrungthaiCustomTheme.defaultIconBarItemWidth, height: ONEKrungthaiCustomTheme.defaultIconBarItemHeight)
        rightButtonItems.append(optionButton)
        
        // Check is current login user profile
        if !screenViewModel.isCurrentUser {
            rightButtonItems.removeFirst() // Case : Isn't current login user profile -> remove create post button
        }
        
        // Group all button to UIBarButtonItem
        rightBarButtons = ONEKrungthaiCustomTheme.groupButtonsToUIBarButtonItem(buttons: rightButtonItems)
        
        // Set custom stack view to UIBarButtonItem
        navigationItem.rightBarButtonItem = rightBarButtons
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
        AmityEventHandler.shared.createPostBeingPrepared(from: self, postTarget: .myFeed, menustyle: .pullDownMenuFromNavigationButton, selectItem: rightBarButtons)
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
