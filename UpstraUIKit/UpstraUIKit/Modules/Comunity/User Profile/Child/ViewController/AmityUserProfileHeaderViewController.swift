//
//  AmityUserProfileHeaderViewController.swift
//  AmityUIKit
//
//  Created by Nontapat Siengsanor on 29/9/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import AmitySDK
import UIKit

class AmityUserProfileHeaderViewController: AmityViewController, AmityRefreshable {
    
    // MARK: - Properties
    private var screenViewModel: AmityUserProfileHeaderScreenViewModelType!
    private var settings: AmityUserProfilePageSettings!
    
    // MARK: - IBOutlet Properties
    @IBOutlet weak private var avatarView: AmityAvatarView!
    @IBOutlet weak private var displayNameLabel: UILabel!
    @IBOutlet weak private var titleNameLabel: UILabel!
    @IBOutlet weak private var descriptionLabel: UILabel!
    @IBOutlet weak private var editProfileButton: AmityButton!
    @IBOutlet weak private var messageButton: AmityButton!
    @IBOutlet weak private var followingButton: AmityButton!
    @IBOutlet weak private var followersButton: AmityButton!
    @IBOutlet weak private var followButton: AmityButton!
    @IBOutlet weak private var messageFriendButton: AmityButton!
    @IBOutlet weak private var contactFriendButton: AmityButton!
    @IBOutlet weak private var followRequestsStackView: UIStackView!
    @IBOutlet weak private var followRequestBackgroundView: UIView!
    @IBOutlet weak private var dotView: UIView!
    @IBOutlet weak private var pendingRequestsLabel: UILabel!
    @IBOutlet weak private var followRequestDescriptionLabel: UILabel!
    @IBOutlet weak private var ktbContainerView: UIView!
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    private var isScrollViewReachedLowestPoint: Bool = false
    
    private var userId: String = ""

    // MARK: Initializer
    static func make(withUserId userId: String, settings: AmityUserProfilePageSettings) -> AmityUserProfileHeaderViewController {
        let viewModel = AmityUserProfileHeaderScreenViewModel(userId: userId)
        let vc = AmityUserProfileHeaderViewController(nibName: AmityUserProfileHeaderViewController.identifier, bundle: AmityUIKitManager.bundle)
        vc.screenViewModel = viewModel
        vc.settings = settings
        vc.userId = userId
        return vc
    }
    
    // MARK: - View's life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewNavigation()
        setupDisplayName()
        setupDescription()
        setupEditButton()
        setupChatButton()
        setupViewModel()
        setupFollowingButton()
        setupFollowersButton()
        setupFollowButton()
        setupFollowRequestsView()
        setupMessageButton()
        setupContactButton()
        
        /* [Custom for ONE Krungthai] Add viewcontroller to ONEKrungthaiCustomTheme class for set theme */
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)
        
        // Set background app for this navigation bar
        theme?.setBackgroundApp(index: 0, isUserProfile: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        /* [Custom for ONE Krungthai] Check view is initialized and is scroll view reached lower point */
        if isScrollViewReachedLowestPoint { // Case : View is initialized and is scroll view reached lower point
            theme?.setBackgroundNavigationBar()
        } else { // Case : View isn't initialize or is scroll view reached topper point
            theme?.clearNavigationBarSetting()
        }
        
        /* [Fix-defect] Setup notification center observer if view appear for handle scroll view UI */
        setupNotificationCenter()
        
        handleRefreshing()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        /* [Fix-defect] Delete observer notification center if view diappeared for cancel handle scroll view UI processing */
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Refreshable
    
    func handleRefreshing() {
        screenViewModel.action.fetchUserData()
        screenViewModel.action.fetchFollowInfo()
    }
    
    // MARK: - Setup
    
    private func setupViewNavigation() {
        navigationController?.setBackgroundColor(with: .clear, shadow: false)
    }
    
    private func setupDisplayName() {
        avatarView.placeholder = AmityIconSet.defaultAvatar
        displayNameLabel.text = ""
        displayNameLabel.font = AmityFontSet.headerLine
        displayNameLabel.textColor = AmityColorSet.base
        displayNameLabel.numberOfLines = 3
        
        titleNameLabel.text = ""
        titleNameLabel.font = AmityFontSet.title
        titleNameLabel.textColor = AmityColorSet.base
        titleNameLabel.numberOfLines = 1
        titleNameLabel.isHidden = true
    }
    
    private func setupDescription() {
        descriptionLabel.text = ""
        descriptionLabel.font = AmityFontSet.body
        descriptionLabel.textColor = AmityColorSet.base
        descriptionLabel.numberOfLines = 0
    }
    
    private func setupEditButton() {
        editProfileButton.setImage(AmityIconSet.iconEdit, position: .left)
        editProfileButton.setTitle(AmityLocalizedStringSet.communityDetailEditProfileButton.localizedString, for: .normal)
        editProfileButton.tintColor = AmityColorSet.secondary
        editProfileButton.layer.borderColor = AmityColorSet.base.blend(.shade3).cgColor
        editProfileButton.layer.borderWidth = 1
        editProfileButton.layer.cornerRadius = editProfileButton.frame.height / 2
        editProfileButton.isHidden = true
        editProfileButton.setTitleFont(AmityFontSet.bodyBold)
    }
    
    private func setupChatButton() {
        messageButton.setImage(AmityIconSet.iconChat, position: .left)
        messageButton.setTitle(AmityLocalizedStringSet.communityDetailMessageButton.localizedString, for: .normal)
        messageButton.tintColor = AmityColorSet.secondary
        messageButton.layer.borderColor = AmityColorSet.secondary.blend(.shade3).cgColor
        messageButton.layer.borderWidth = 1
        messageButton.layer.cornerRadius = messageButton.frame.height / 2
        messageButton.isHidden = settings.shouldChatButtonHide
    }
    
    private func setupViewModel() {
        screenViewModel.delegate = self
    }
    
    private func setupFollowingButton() {
        let attribute = AmityAttributedString()
        attribute.setBoldFont(for: AmityFontSet.title)
        attribute.setBoldColor(for: AmityColorSet.secondary)
        attribute.setNormalFont(for: AmityFontSet.caption)
        attribute.setNormalColor(for: UIColor(hex: "#898E9E"))
        followingButton.attributedString = attribute
        followingButton.isHidden = false
        followingButton.isUserInteractionEnabled = true /* [Custom for ONE Krungthai] Force following/followers button can interaction all scenarioes | Set isUserInteractionEnabled to true */
        followingButton.addTarget(self, action: #selector(followingAction(_:)), for: .touchUpInside)
        followingButton.titleLabel?.numberOfLines = 0
        followingButton.titleLabel?.textAlignment = .center
        
        let title = String.localizedStringWithFormat(AmityLocalizedStringSet.userDetailFollowingCount.localizedString, "0")
        followingButton.attributedString.setTitle(title)
//        followingButton.attributedString.setBoldText(for: ["0"])
//        followingButton.setAttributedTitle()
    }
    
    private func setupFollowersButton() {
        let attribute = AmityAttributedString()
        attribute.setBoldFont(for: AmityFontSet.title)
        attribute.setBoldColor(for: AmityColorSet.secondary)
        attribute.setNormalFont(for: AmityFontSet.caption)
        attribute.setNormalColor(for: UIColor(hex: "#898E9E"))
        followersButton.attributedString = attribute
        followersButton.isHidden = false
        followersButton.isUserInteractionEnabled = true /* [Custom for ONE Krungthai] Force following/followers button can interaction all scenarioes | Set isUserInteractionEnabled to true */
        followersButton.addTarget(self, action: #selector(followersAction(_:)), for: .touchUpInside)
        followersButton.titleLabel?.numberOfLines = 0
        followersButton.titleLabel?.textAlignment = .center
        
        let title = String.localizedStringWithFormat(AmityLocalizedStringSet.userDetailFollowersCount.localizedString, "0")
        followingButton.attributedString.setTitle(title)
//        followingButton.attributedString.setBoldText(for: ["0"])
//        followingButton.setAttributedTitle()
    }
    
    private func setupFollowButton() {
        followButton.setTitleShadowColor(AmityColorSet.baseInverse, for: .normal)
        followButton.setTitleFont(AmityFontSet.bodyBold)
        followButton.tintColor = AmityColorSet.baseInverse
        followButton.backgroundColor = AmityColorSet.primary
        followButton.layer.cornerRadius = followButton.frame.height / 2
        followButton.setTitle(AmityLocalizedStringSet.userDetailFollowButtonFollow.localizedString, for: .normal)
        followButton.setImage(AmityIconSet.iconAdd, position: .left)
        
        followButton.isHidden = true
    }
    
    private func setupFollowRequestsView() {
        followRequestsStackView.isHidden = true
        
        followRequestBackgroundView.backgroundColor = AmityColorSet.secondary.blend(.shade4)
        followRequestBackgroundView.layer.cornerRadius = 4
        
        dotView.layer.cornerRadius = 3
        dotView.backgroundColor = AmityColorSet.primary
        
        pendingRequestsLabel.font = AmityFontSet.bodyBold
        pendingRequestsLabel.textColor = AmityColorSet.secondary
        pendingRequestsLabel.text = AmityLocalizedStringSet.userDetailsPendingRequests.localizedString
        
        followRequestDescriptionLabel.font = AmityFontSet.caption
        followRequestDescriptionLabel.textColor = AmityColorSet.base.blend(.shade1)
        followRequestDescriptionLabel.text = AmityLocalizedStringSet.userDetailsPendingRequestsDescription.localizedString
    }
    
    private func setupMessageButton() {
        messageFriendButton.setImage(AmityIconSet.iconMessageProfile, position: .left)
        messageFriendButton.setTitle("Message", for: .normal)
        messageFriendButton.tintColor = AmityColorSet.base
        messageFriendButton.layer.borderColor = AmityColorSet.base.blend(.shade3).cgColor
        messageFriendButton.layer.borderWidth = 1
        messageFriendButton.layer.cornerRadius = messageFriendButton.frame.height / 2
        messageFriendButton.setTitleFont(AmityFontSet.bodyBold)
    }
    
    private func setupContactButton() {
        contactFriendButton.setImage(AmityIconSet.iconContactProfile, position: .left)
        contactFriendButton.setTitle("Contact", for: .normal)
        contactFriendButton.tintColor = AmityColorSet.base
        contactFriendButton.layer.borderColor = AmityColorSet.base.blend(.shade3).cgColor
        contactFriendButton.layer.borderWidth = 1
        contactFriendButton.layer.cornerRadius = messageFriendButton.frame.height / 2
        contactFriendButton.setTitleFont(AmityFontSet.bodyBold)
    }
    
    private func setupNotificationCenter() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleScrollViewReachedLowestPoint), name: .scrollViewReachedLowestPoint, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleScrollViewReachedTopperPoint), name: .scrollViewReachedTopperPoint, object: nil)
    }
    
    @objc func handleScrollViewReachedLowestPoint() {
        /* [Original] */
//        titleNameLabel.isHidden = false
//
//        //  Hide all don't to show
//        avatarView.isHidden = true
//        displayNameLabel.isHidden = true
//        descriptionLabel.isHidden = true
//        followingButton.isHidden = true
//        followersButton.isHidden = true
//        followButton.isHidden = true
        
        /* [Fix-defect] Set static value for check in viewWillAppear cycle and set navigation bar */
        if !isScrollViewReachedLowestPoint {
            theme?.setBackgroundNavigationBar()
            isScrollViewReachedLowestPoint = true
        }
    }
    
    @objc func handleScrollViewReachedTopperPoint() {
        /* [Original] */
//        titleNameLabel.isHidden = true
//
//        //  Show all
//        avatarView.isHidden = false
//        displayNameLabel.isHidden = false
//        descriptionLabel.isHidden = false
//        followingButton.isHidden = false
//        followersButton.isHidden = false
//        followButton.isHidden = false
        
        /* [Fix-defect] Set static value for check in viewWillAppear cycle and clear navigation bar setting */
        if isScrollViewReachedLowestPoint {
            theme?.clearNavigationBarSetting()
            isScrollViewReachedLowestPoint = false
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func updateView(with user: AmityUserModel) {
        avatarView.setImage(withImageURL: user.avatarURL, placeholder: AmityIconSet.defaultAvatar)
        displayNameLabel.text = user.displayName
        titleNameLabel.text = user.displayName
        descriptionLabel.text = user.about
        editProfileButton.isHidden = !user.isCurrentUser
        messageButton.isHidden = settings.shouldChatButtonHide || user.isCurrentUser
        ktbContainerView.isHidden = user.isCurrentUser
    }
    
    private func updateFollowInfo(with model: AmityFollowInfo) {
        updateFollowingCount(with: model.followingCount)
        updateFollowerCount(with: model.followerCount)
    }
    
    private func updateFollowingCount(with followingCount: Int) {
        let value = followingCount.formatUsingAbbrevation()
        let string = String.localizedStringWithFormat(AmityLocalizedStringSet.userDetailFollowingCount.localizedString, value)
        followingButton.attributedString.setTitle(string)
        followingButton.attributedString.setBoldText(for: [value])
        followingButton.setAttributedTitle()
    }
    
    private func updateFollowerCount(with followerCount: Int) {
        let value = followerCount.formatUsingAbbrevation()
        let string = String.localizedStringWithFormat(AmityLocalizedStringSet.userDetailFollowersCount.localizedString, value)
        followersButton.attributedString.setTitle(string)
        followersButton.attributedString.setBoldText(for: [value])
        followersButton.setAttributedTitle()
    }
    
    private func updateFollowButton(with status: AmityFollowStatus) {
        switch status {
        case .accepted:
            followButton.isHidden = true
        case .pending:
            followButton.isHidden = true
            followButton.setTitle(AmityLocalizedStringSet.userDetailFollowButtonCancel.localizedString, for: .normal)
            followButton.setImage(AmityIconSet.Follow.iconFollowPendingRequest, position: .left)
            followButton.backgroundColor = .white
            followButton.layer.borderColor = AmityColorSet.base.blend(.shade3).cgColor
            followButton.layer.borderWidth = 1
            followButton.tintColor = AmityColorSet.secondary
        case .blocked:
            followButton.isHidden = true
        case .none:
            followButton.isHidden = false
            followButton.setTitle(AmityLocalizedStringSet.userDetailFollowButtonFollow.localizedString, for: .normal)
            followButton.setImage(AmityIconSet.iconAdd, position: .left)
            followButton.backgroundColor = AmityColorSet.primary
            followButton.layer.borderWidth = 0
            followButton.tintColor = AmityColorSet.baseInverse
        @unknown default:
            fatalError()
        }
    }
    
    private func updateFollowRequestsView(with count: Int) {
        followRequestsStackView.isHidden = count == 0
    }
    
    @IBAction func editButtonTap(_ sender: Any) {
        AmityEventHandler.shared.editUserDidTap(from: self, userId: screenViewModel.userId)
    }
    
    @IBAction func chatButtonTap(_ sender: Any) {
        screenViewModel.action.createChannel()
    }
    
    @IBAction func followAction(_ sender: UIButton) {
        let status = screenViewModel.dataSource.followStatus ?? .none
        switch status {
        case .pending:
            unfollow()
        case .none:
            follow()
            updateFollowButton(with: .pending)
        default:
            break
        }
    }
    
    @objc func followingAction(_ sender: UIButton) {
        handleTapAction(isFollowersSelected: false)
    }
    
    @objc func followersAction(_ sender: UIButton) {
        handleTapAction(isFollowersSelected: true)
    }
    
    @IBAction func followRequestsAction(_ sender: UIButton) {
        let requestsViewController = AmityFollowRequestsViewController.make(withUserId: screenViewModel.dataSource.userId)
        navigationController?.pushViewController(requestsViewController, animated: true)
    }
    
    @IBAction func messageFriendAction(_ sender: UIButton) {
        AmityEventHandler.shared.showKTBLoading()
        screenViewModel.action.createChannel()
    }
    
    @IBAction func contachFriendAction(_ sender: UIButton) {
        let userId = userId.replacingOccurrences(of: "1001", with: "")
        AmityEventHandler.shared.openKTBContact(from: self, id: userId)
    }
}

// MARK:- Follow/Unfollow handlers
private extension AmityUserProfileHeaderViewController {
    func follow() {
        screenViewModel.action.follow()
    }
    
    func unfollow() {
        screenViewModel.action.unfollow()
    }
    
    func handleTapAction(isFollowersSelected: Bool) {
        let vc = AmityUserFollowersViewController.make(withUserId: screenViewModel.dataSource.userId, isFollowersSelected: isFollowersSelected)
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension AmityUserProfileHeaderViewController : AmityUserProfileHeaderScreenViewModelDelegate {
    func screenViewModel(_ viewModel: AmityUserProfileHeaderScreenViewModelType, failure error: AmityError) {
    }
    
    func screenViewModel(_ viewModel: AmityUserProfileHeaderScreenViewModelType, didGetUser user: AmityUserModel) {
        updateView(with: user)
    }
    
    func screenViewModel(_ viewModel: AmityUserProfileHeaderScreenViewModelType, didGetFollowInfo followInfo: AmityFollowInfo) {
        updateFollowInfo(with: followInfo)
        /* [Custom for ONE Krungthai] Force following/followers button can interaction all scenarioes | Comment isUserInteractionEnabled code */
        if let pendingCount = screenViewModel.dataSource.followInfo?.pendingCount {
            updateFollowRequestsView(with: pendingCount)
//            followersButton.isUserInteractionEnabled = true
//            followingButton.isUserInteractionEnabled = true
        } else if let status = screenViewModel.dataSource.followInfo?.status {
            updateFollowButton(with: status)
//            followersButton.isUserInteractionEnabled = status == .accepted
//            followingButton.isUserInteractionEnabled = status == .accepted
        }
    }
    
    func screenViewModel(_ viewModel: AmityUserProfileHeaderScreenViewModelType, didCreateChannel channel: AmityChannel) {
        AmityEventHandler.shared.hideKTBLoading()
        AmityChannelEventHandler.shared.channelDidTap(from: self, channelId: channel.channelId, subChannelId: channel.defaultSubChannelId)
    }
    
    func screenViewModel(_ viewModel: AmityUserProfileHeaderScreenViewModelType, didFollowSuccess status: AmityFollowStatus) {
        updateFollowButton(with: status)
    }
    
    func screenViewModel(_ viewModel: AmityUserProfileHeaderScreenViewModelType, didUnfollowSuccess status: AmityFollowStatus) {
        updateFollowButton(with: status)
    }
    
    func screenViewModelDidFollowFail() {
        updateFollowButton(with: .none)
        let userName = screenViewModel.dataSource.user?.displayName ?? ""
        let title = String.localizedStringWithFormat(AmityLocalizedStringSet.userDetailsUnableToFollow.localizedString, userName)
        let alert = UIAlertController(title: title, message: AmityLocalizedStringSet.somethingWentWrongWithTryAgain.localizedString, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AmityLocalizedStringSet.General.ok.localizedString, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func screenViewModelDidUnfollowFail() {
        updateFollowButton(with: .pending)
    }
}
