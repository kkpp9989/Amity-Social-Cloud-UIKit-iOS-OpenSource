//
//  AmityChatFriendPageViewController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 2/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityChatFriendPageViewController: AmityViewController, IndicatorInfoProvider {
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var refreshErrorView: UIView!
    @IBOutlet private var refreshErrorLabel: UILabel!
    
    // MARK: - Properties
    private var type: AmityFollowerViewType?
    private var emptyView = AmitySearchEmptyView()
    public var pageTitle: String?
    private var screenViewModel: AmityFollowersListScreenViewModelType!
    private var searchController = UISearchController(searchResultsController: nil)
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupScreenViewModle()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        screenViewModel.action.getFollowsList()
    }
    
    static func make(type: AmityFollowerViewType) -> AmityChatFriendPageViewController {
        let viewModel: AmityFollowersListScreenViewModelType = AmityFollowersListScreenViewModel(userId: AmityUIKitManagerInternal.shared.currentUserId, type: type)
        let vc = AmityChatFriendPageViewController(nibName: AmityChatFriendPageViewController.identifier, bundle: AmityUIKitManager.bundle)

        vc.type = type
        vc.screenViewModel = viewModel
        
        return vc
    }
    
    // MARK: - Setup viewModel
    private func setupScreenViewModle() {
        screenViewModel.delegate = self
    }
    
    // MARK: - Setup views
    private func setupView() {
        view.backgroundColor = AmityColorSet.backgroundColor
        setupTableView()
        setupRefreshControl()
        setupRefreshErrorView()
    }
    
    private func setupTableView() {
        tableView.register(AmityFollowerTableViewCell.nib, forCellReuseIdentifier: AmityFollowerTableViewCell.identifier)
        tableView.separatorColor = .clear
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = AmityColorSet.backgroundColor
        tableView.tableFooterView = UIView()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(handleRefreshingControl), for: .valueChanged)
        refreshControl.tintColor = AmityColorSet.base.blend(.shade3)
        tableView.refreshControl = refreshControl
    }
    
    private func setupRefreshErrorView() {
        refreshErrorView.backgroundColor = AmityColorSet.secondary
        refreshErrorView.alpha = 0.8
        refreshErrorView.isHidden = true
        
        refreshErrorLabel.font = AmityFontSet.bodyBold
        refreshErrorLabel.textColor = .white
        refreshErrorLabel.textAlignment = .center
        refreshErrorLabel.text = AmityLocalizedStringSet.Follow.canNotRefreshFeed.localizedString
    }
    
    private func setupSearchController() {
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = AmityLocalizedStringSet.General.search.localizedString
        searchController.searchBar.tintColor = AmityColorSet.base
        searchController.searchBar.returnKeyType = .done
        searchController.searchBar.backgroundImage = UIImage()
        searchController.searchBar.barTintColor = AmityColorSet.backgroundColor
        searchController.searchBar.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)

        (searchController.searchBar.value(forKey: "cancelButton") as? UIButton)?.tintColor = AmityColorSet.base

        if #available(iOS 13, *) {
            searchController.searchBar.searchTextField.backgroundColor = AmityColorSet.secondary.blend(.shade4)
            searchController.searchBar.searchTextField.textColor = AmityColorSet.base
            searchController.searchBar.searchTextField.leftView?.tintColor = AmityColorSet.base.blend(.shade2)
        } else {
            if let textField = (searchController.searchBar.value(forKey: "searchField") as? UITextField) {
                textField.backgroundColor = AmityColorSet.secondary.blend(.shade4)
                textField.tintColor = AmityColorSet.base
                textField.textColor = AmityColorSet.base
                textField.leftView?.tintColor = AmityColorSet.base.blend(.shade2)
            }
        }
    }
    
    func indicatorInfo(for pagerTabStripController: AmityPagerTabViewController) -> IndicatorInfo {
        return IndicatorInfo(title: pageTitle)
    }
}

// MARK: - UITableView Delegate
extension AmityChatFriendPageViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.isBottomReached {
            screenViewModel.action.loadMoreFollowingList()
        }
        
        guard let cell = cell as? AmityFollowerTableViewCell,
              let model = screenViewModel.dataSource.item(at: indexPath) else {
            return
        }
        cell.display(with: model)
        cell.setIndexPath(with: indexPath)
        cell.delegate = self
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UITableView DataSource
extension AmityChatFriendPageViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return screenViewModel.dataSource.numberOfItems()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: AmityFollowerTableViewCell.identifier, for: indexPath)
    }
    
}

// MARK: - AmityFollowerTableViewCellDelegate
extension AmityChatFriendPageViewController: AmityFollowerTableViewCellDelegate {
    func didPerformAction(at indexPath: IndexPath, action: AmityFollowerAction) {
        switch action {
        case .tapAvatar, .tapDisplayName:
            guard let user = screenViewModel.dataSource.item(at: indexPath) else { return }
            AmityEventHandler.shared.userDidTap(from: self, userId: user.userId)
        case .tapOption:
            handleOptionTap(for: indexPath)
        }
    }
}

// MARK:- Private Methods
private extension AmityChatFriendPageViewController {
    func handleOptionTap(for indexPath: IndexPath) {
        screenViewModel.action.getReportUserStatus(at: indexPath)
    }
    
    @objc func handleRefreshingControl() {
        screenViewModel.action.getFollowsList()
    }
}

// MARK:- UISearchBarDelegate
extension AmityChatFriendPageViewController: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        screenViewModel.action.getFollowsList()
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        screenViewModel.action.getFollowsList()
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    public func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.setShowsCancelButton(true, animated: true)
        return true
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        screenViewModel.action.getFollowsList()
        searchBar.resignFirstResponder()
    }
}

extension AmityChatFriendPageViewController: AmityFollowersListScreenViewModelDelegate {
    func screenViewModel(_ viewModel: AmityFollowersListScreenViewModelType, didRemoveUser at: IndexPath) {
        AmityHUD.show(.success(message: AmityLocalizedStringSet.General.done.localizedString))
    }
    
    func screenViewModel(_ viewModel: AmityFollowersListScreenViewModelType, failure error: AmityError) {
        refreshControl.endRefreshing()
    }
    
    func screenViewModel(_ viewModel: AmityFollowersListScreenViewModelType, didGetReportUserStatus isReported: Bool, at indexPath: IndexPath) {
        let bottomSheet = BottomSheetViewController()
        let contentView = ItemOptionView<TextItemOption>()
        bottomSheet.sheetContentView = contentView
        bottomSheet.isTitleHidden = true
        bottomSheet.modalPresentationStyle = .overFullScreen

        var options: [TextItemOption] = []

        var option: TextItemOption
        let optionTitle = isReported ? AmityLocalizedStringSet.General.unreportUser.localizedString : AmityLocalizedStringSet.General.reportUser.localizedString
        option = TextItemOption(title: optionTitle) { [weak self] in
            isReported ? self?.screenViewModel.action.unreportUser(at: indexPath) : self?.screenViewModel.action.reportUser(at: indexPath)
        }

        options.append(option)
        
        if self.screenViewModel.dataSource.isCurrentUser && type == .followers {
            let removeUserOption = TextItemOption(title: AmityLocalizedStringSet.UserSettings.UserSettingsRemove.removeUser.localizedString, textColor: AmityColorSet.alert) { [weak self] in
                guard let self = self, let user = self.screenViewModel.dataSource.item(at: indexPath) else { return }
                
                let alertTitle = String.localizedStringWithFormat(AmityLocalizedStringSet.UserSettings.UserSettingsRemove.removeUserTitle.localizedString, user.displayName)
                let message = String.localizedStringWithFormat(AmityLocalizedStringSet.UserSettings.UserSettingsRemove.removeUserDescription.localizedString, user.displayName)

                AmityAlertController.present(title: alertTitle, message: message, actions: [.cancel(handler: nil), .custom(title: AmityLocalizedStringSet.General.remove.localizedString, style: .destructive, handler: { [weak self] in
                        self?.screenViewModel.action.removeUser(at: indexPath)
                })], from: self)
            }

            options.append(removeUserOption)
        }
        
        contentView.configure(items: options, selectedItem: nil)
        present(bottomSheet, animated: false, completion: nil)
    }
    
    func screenViewModelDidGetListSuccess() {
        refreshControl.endRefreshing()
        tableView.reloadData()
    }
    
    func screenViewModelDidGetListFail() {
        refreshControl.endRefreshing()
        refreshErrorView.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) { [weak self] in
            self?.refreshErrorView.isHidden = true
        }
    }
    
    func screenViewModel(_ viewModel: AmityFollowersListScreenViewModelType, didReportUserSuccess at: IndexPath) {
        AmityHUD.show(.success(message: AmityLocalizedStringSet.HUD.reportSent.localizedString))
    }
    
    func screenViewModel(_ viewModel: AmityFollowersListScreenViewModelType, didUnreportUserSuccess at: IndexPath) {
        AmityHUD.show(.success(message: AmityLocalizedStringSet.HUD.unreportSent.localizedString))
    }
}
