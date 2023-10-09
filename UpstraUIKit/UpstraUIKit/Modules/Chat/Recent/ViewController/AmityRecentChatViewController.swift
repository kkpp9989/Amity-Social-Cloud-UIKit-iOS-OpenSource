//
//  AmityRecentChatViewController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 7/7/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit
import AmitySDK

/// Recent chat
public final class AmityRecentChatViewController: AmityViewController, IndicatorInfoProvider {
    
    var pageTitle: String?
    let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
    
    func indicatorInfo(for pagerTabStripController: AmityPagerTabViewController) -> IndicatorInfo {
        return IndicatorInfo(title: pageTitle)
    }
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var tableView: UITableView!
    
    weak var delegate: GroupChatCreatorViewControllerDelegate?
    
    // MARK: - Properties
    private var screenViewModel: AmityRecentChatScreenViewModelType!
            
    private lazy var emptyView: AmityEmptyView = {
        let emptyView = AmityEmptyView(frame: tableView.frame)
        emptyView.update(title: AmityLocalizedStringSet.emptyChatList.localizedString,
                         subtitle: nil,
                         image: AmityIconSet.emptyChat)
        return emptyView
    }()
    
    // MARK: - View lifecycle
    private init(viewModel: AmityRecentChatScreenViewModelType) {
        screenViewModel = viewModel
        super.init(nibName: AmityRecentChatViewController.identifier, bundle: AmityUIKitManager.bundle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupScreenViewModel()
        setupView()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //  Stop syncing presence for all users as user
        screenViewModel.action.unsyncAllChannelPresence()
    }
    
    public static func make(channelType: AmityChannelType = .conversation) -> AmityRecentChatViewController {
        let viewModel: AmityRecentChatScreenViewModelType = AmityRecentChatScreenViewModel(channelType: channelType)
        return AmityRecentChatViewController(viewModel: viewModel)
    }
}

// MARK: - Setup ViewModel
private extension AmityRecentChatViewController {
    func setupScreenViewModel() {
        screenViewModel.delegate = self
        screenViewModel.action.viewDidLoad()
    }
}

// MARK: - Setup View
private extension AmityRecentChatViewController {
    func setupView() {
        if screenViewModel.dataSource.isAddMemberBarButtonEnabled() {
            let addImage = UIImage(named: "icon_chat_create", in: AmityUIKitManager.bundle, compatibleWith: nil)
            let barButton = UIBarButtonItem(image: addImage, style: .plain, target: self, action: #selector(didClickAdd(_:)))
            navigationItem.rightBarButtonItem = barButton
        }
        
        setupTableView()
    }
    
    func setupTableView() {
        view.backgroundColor = AmityColorSet.backgroundColor
        tableView.register(AmityRecentChatTableViewCell.nib, forCellReuseIdentifier: AmityRecentChatTableViewCell.identifier)
        tableView.register(AmityOwnerChatTableViewCell.nib, forCellReuseIdentifier: AmityOwnerChatTableViewCell.identifier)
        tableView.backgroundColor = AmityColorSet.backgroundColor
        tableView.separatorInset.left = 64
        tableView.showsVerticalScrollIndicator = false
        tableView.tableFooterView = UIView()
        tableView.backgroundView = emptyView
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @objc func didClickAdd(_ barButton: UIBarButtonItem) {
        AmityChannelEventHandler.shared.channelCreateNewChat(
            from: self,
            completionHandler: { [weak self] storeUsers in
                guard let weakSelf = self else { return }
                weakSelf.screenViewModel.action.createChannel(users: storeUsers)
        })
    }
}

extension AmityRecentChatViewController: GroupChatCreatorViewControllerDelegate {

    func tapCreateButton(channelId: String, subChannelId: String) {
        AmityChannelEventHandler.shared.channelDidTap(from: self, channelId: channelId, subChannelId: subChannelId)
    }
}

// MARK: - UITableView Delegate
extension AmityRecentChatViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section != 0 {
            screenViewModel.action.join(at: indexPath)
        } else {
            let userStatusVC = UserStatusViewController(nibName: UserStatusViewController.identifier, bundle: AmityUIKitManager.bundle)
            userStatusVC.delegate = self
            userStatusVC.view.tag = 1
            window?.rootViewController?.addChild(userStatusVC)
            window?.addSubview(userStatusVC.view)
        }
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.isBottomReached {
            screenViewModel.action.loadMore()
        }
        
        if let _ = cell as? AmityRecentChatTableViewCell {
            let channel = screenViewModel.dataSource.channel(at: indexPath)
            screenViewModel.action.syncChannelPresence(channel.channelId)
        }
    }
    
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let _ = cell as? AmityRecentChatTableViewCell {
            let channel = screenViewModel.dataSource.channel(at: indexPath)
            screenViewModel.action.unsyncChannelPresence(channel.channelId)
        }
    }
}

// MARK: - UITableView DataSource
extension AmityRecentChatViewController: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return screenViewModel.dataSource.numberOfRow(in: section)
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 72
        } else {
            return UITableView.automaticDimension
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: AmityOwnerChatTableViewCell.identifier, for: indexPath)
            configureOwner(for: cell)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: AmityRecentChatTableViewCell.identifier, for: indexPath)
            configure(for: cell, at: indexPath)
            return cell
        }
        
    }
    
    private func configureOwner(for cell: UITableViewCell) {
        if let cell = cell as? AmityOwnerChatTableViewCell {
            cell.setupDisplay()
        }
    }
    
    private func configure(for cell: UITableViewCell, at indexPath: IndexPath) {
        if let cell = cell as? AmityRecentChatTableViewCell {
            let channel = screenViewModel.dataSource.channel(at: indexPath)
            cell.display(with: channel)
        }
    }
}

extension AmityRecentChatViewController: AmityRecentChatScreenViewModelDelegate {
    func screenViewModelDidCreateCommunity(channelId: String, subChannelId: String) {
        AmityChannelEventHandler.shared.channelDidTap(from: self, channelId: channelId, subChannelId: subChannelId)
    }
    
    func screenViewModelDidFailedCreateCommunity(error: String) {
        AmityHUD.show(.error(message: AmityLocalizedStringSet.CommunityChannelCreation.failedToCreate.localizedString))
    }
    
    func screenViewModelDidGetChannel() {
        tableView.reloadData()
    }
    
    func screenViewModelLoadingState(for state: AmityLoadingState) {
        switch state {
        case .loaded:
            tableView.tableFooterView = UIView()
        case .loading:
            tableView.showLoadingIndicator()
        case .initial:
            break
        }
    }
    
    func screenViewModelRoute(for route: AmityRecentChatScreenViewModel.Route) {
        switch route {
        case .messageView(let channelId, let subChannelId):
            AmityChannelEventHandler.shared.channelDidTap(from: self, channelId: channelId, subChannelId: subChannelId)
        }
    }
    
    func screenViewModelEmptyView(isEmpty: Bool) {
        tableView.backgroundView = isEmpty ? emptyView : nil
    }
}

extension AmityRecentChatViewController: UserStatusDelegate {
    func didClose() {
        window?.subviews.filter({$0.tag == 1}).forEach({$0.removeFromSuperview()})
        screenViewModel?.action.update { [self] result in
            switch result {
            case .success:
                reloadData()
            case .failure(let error):
                print("Update failed with error: \(error)")
            }
        }
    }
    
    private func reloadData() {
        DispatchQueue.main.async { [self] in
            tableView.reloadData()
        }
    }
    
}
