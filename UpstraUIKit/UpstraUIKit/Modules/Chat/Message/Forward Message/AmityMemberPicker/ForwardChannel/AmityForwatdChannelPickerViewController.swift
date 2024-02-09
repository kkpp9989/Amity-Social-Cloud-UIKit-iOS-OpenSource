//
//  AmityForwatdChannelPickerViewController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 25/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

public enum AmityChannelViewType {
    case recent, group, broadcast
}

extension AmityForwatdChannelPickerViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: AmityPagerTabViewController) -> IndicatorInfo {
        return IndicatorInfo(title: pageTitle)
    }
}

class AmityForwatdChannelPickerViewController: AmityViewController {
    
    // MARK: - Callback
    public var selectUsersHandler: ((_ newSelectedUsers: [AmitySelectMemberModel], _ storeUsers: [AmitySelectMemberModel],_ title: String, _ keyword: String) -> Void)?

    // MARK: - IBOutlet Properties
    @IBOutlet private var searchBar: UISearchBar!
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var label: UILabel!
    
    // MARK: - Properties
    private var screenViewModel: AmityForwardChannelPickerScreenViewModelType!
    private var doneButton: UIBarButtonItem?
    
    // MARK: - Optional Properties (Keep data from previous viewcontroller for send next viewcontroller)
    private var broadcastMessage: AmityBroadcastMessageCreatorModel?
    
    var pageTitle: String?
    var lastSearchKeyword: String = ""
    private let debouncer = Debouncer(delay: 0.3)

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        screenViewModel.delegate = self
        screenViewModel.action.getChannels()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    public static func make(pageTitle: String, users: [AmitySelectMemberModel] = [], type: AmityChannelViewType) -> AmityForwatdChannelPickerViewController {
        let viewModel: AmityForwardChannelPickerScreenViewModelType = AmityForwardChannelPickerScreenViewModel(type: type)
        viewModel.setCurrentUsers(users: users)
        let vc = AmityForwatdChannelPickerViewController(nibName: AmityForwatdChannelPickerViewController.identifier, bundle: AmityUIKitManager.bundle)
        vc.screenViewModel = viewModel
        vc.pageTitle = pageTitle
        return vc
    }
    
    public static func make(pageTitle: String, users: [AmitySelectMemberModel] = [], type: AmityChannelViewType, broadcastMessage: AmityBroadcastMessageCreatorModel) -> AmityForwatdChannelPickerViewController {
        let viewModel: AmityForwardChannelPickerScreenViewModelType = AmityForwardChannelPickerScreenViewModel(type: type)
        viewModel.setCurrentUsers(users: users)
        let vc = AmityForwatdChannelPickerViewController(nibName: AmityForwatdChannelPickerViewController.identifier, bundle: AmityUIKitManager.bundle)
        vc.screenViewModel = viewModel
        vc.pageTitle = pageTitle
        vc.broadcastMessage = broadcastMessage
        return vc
    }
    
    public func setNewSelectedUsers(users: [AmitySelectMemberModel], isFromAnotherTab: Bool, keyword: String) {
        screenViewModel.setNewSelectedUsers(users: users, isFromAnotherTab: isFromAnotherTab, keyword: keyword)
    }
}

private extension AmityForwatdChannelPickerViewController {
    @objc func doneTap() {
        if isLastViewController { // Case : Is last viewcontroller -> Dismiss viewcontroller
            dismiss(animated: true)
        } else {
            if screenViewModel.dataSource.targetType == .broadcast, let broadcastMessage = broadcastMessage { // Case : Isn't last viewcontroller and target type is broadcast -> Push preview select channel viewcontroller
                let previewSelectedViewController = AmityPreviewSelectedFromPickerViewController.make(pageTitle: "Broadcast to", selectedData: screenViewModel.dataSource.getStoreUsers(), broadcastMessage: broadcastMessage)
                previewSelectedViewController.isLastViewController = true
                navigationController?.pushViewController(previewSelectedViewController, animated: true)
            } else { // Case : Isn't last viewcontroller but other target type -> Dismiss viewcontroller
                dismiss(animated: true)
            }
        }
    }
    
    @objc func cancelTap() {
        dismiss(animated: true)
    }
    
    func deleteItem(at indexPath: IndexPath) {
        screenViewModel.action.deselectUser(at: indexPath)
    }
}

private extension AmityForwatdChannelPickerViewController {
    func setupView() {
        setupNavigationBar()
        setupSearchBar()
        setupTableView()
        setupCollectionView()
    }
    
    func setupNavigationBar() {
        view.backgroundColor = AmityColorSet.backgroundColor
        
        let customView = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        customView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: customView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: customView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: customView.trailingAnchor)
        ])
        navigationItem.titleView = customView
        let numberOfSelectedUseres = screenViewModel.dataSource.numberOfSelectedUsers()
        if numberOfSelectedUseres == 0 {
            switch screenViewModel.dataSource.targetType {
            case .broadcast, .group:
                title = "Select group"
            default:
                title = AmityLocalizedStringSet.selectMemberListTitle.localizedString
            }
        } else {
            title = String.localizedStringWithFormat(AmityLocalizedStringSet.selectMemberListSelectedTitle.localizedString, "\(numberOfSelectedUseres)")
        }
        
        doneButton = UIBarButtonItem(title: isLastViewController ? AmityLocalizedStringSet.General.done.localizedString : AmityLocalizedStringSet.General.next.localizedString, style: .plain, target: self, action: #selector(doneTap))
        doneButton?.tintColor = AmityColorSet.primary
        doneButton?.isEnabled = !(numberOfSelectedUseres == 0)
        // [Improvement] Add set font style to label of done button
        doneButton?.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .normal)
        doneButton?.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .disabled)
        doneButton?.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .selected)
        
        if self.navigationController == nil {
            navigationBarType = .custom
            
            let cancelButton = UIBarButtonItem(title: AmityLocalizedStringSet.General.cancel.localizedString, style: .plain, target: self, action: #selector(cancelTap))
            cancelButton.tintColor = AmityColorSet.base
            // [Improvement] Add set font style to label of cancel button
            cancelButton.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .normal)
            cancelButton.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .disabled)
            cancelButton.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .selected)
            
            navigationItem.leftBarButtonItem = cancelButton
        } else {
            navigationBarType = .push
        }
        
        navigationItem.rightBarButtonItem = doneButton
    }
    
    func setupSearchBar() {
        searchBar.backgroundImage = UIImage()
        searchBar.delegate = self
        searchBar.tintColor = AmityColorSet.base
        searchBar.searchTextField.font = AmityFontSet.body
        searchBar.returnKeyType = .done
        (searchBar.value(forKey: "searchField") as? UITextField)?.textColor = AmityColorSet.base
        ((searchBar.value(forKey: "searchField") as? UITextField)?.leftView as? UIImageView)?.tintColor = AmityColorSet.base.blend(.shade2)
        searchBar.text = lastSearchKeyword
    }
    
    func setupTableView() {
        tableView.register(UINib(nibName: AmitySelectMemberListTableViewCell.identifier, bundle: AmityUIKitManager.bundle), forCellReuseIdentifier: AmitySelectMemberListTableViewCell.identifier)
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = AmityColorSet.backgroundColor
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func setupCollectionView() {
        collectionView.register(UINib(nibName: AmitySelectMemberListCollectionViewCell.identifier, bundle: AmityUIKitManager.bundle), forCellWithReuseIdentifier: AmitySelectMemberListCollectionViewCell.identifier)
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .horizontal
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isHidden = screenViewModel.dataSource.numberOfSelectedUsers() == 0
        collectionView.backgroundColor = AmityColorSet.backgroundColor
        collectionView.delegate = self
        collectionView.dataSource = self
    }
}

extension AmityForwatdChannelPickerViewController: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        lastSearchKeyword = searchText
        selectUsersHandler?(screenViewModel.dataSource.getNewSelectedUsers(), screenViewModel.dataSource.getStoreUsers(), AmityLocalizedStringSet.selectMemberListTitle.localizedString, lastSearchKeyword)
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else {
            return
        }
        
        screenViewModel.action.searchUser(with: searchText)
    }
}

extension AmityForwatdChannelPickerViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let user = screenViewModel.dataSource.user(at: indexPath) else { return }
        if !user.isCurrnetUser {
            screenViewModel.action.selectUser(at: indexPath)
        }
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = AmityMemberPickerHeaderView()
        if screenViewModel.dataSource.isSearching() {
            headerView.text = AmityLocalizedStringSet.searchResults.localizedString
        } else {
            headerView.text = screenViewModel.dataSource.alphabetOfHeader(in: section)
        }
        return headerView
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Return a custom height for sections with empty string values
        if screenViewModel.dataSource.alphabetOfHeader(in: section).isEmpty {
            return 0
        } else {
            return 28
        }
    }
}

extension AmityForwatdChannelPickerViewController: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return screenViewModel.numberOfAlphabet()
        
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return screenViewModel.dataSource.numberOfUsers(in: section)
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AmitySelectMemberListTableViewCell.identifier, for: indexPath)
        configure(tableView, for: cell, at: indexPath)
        return cell
    }
    
    private func configure(_ tableView: UITableView, for cell: UITableViewCell, at indexPath: IndexPath) {
        if let cell = cell as? AmitySelectMemberListTableViewCell {
            guard let user = screenViewModel.dataSource.user(at: indexPath) else { return }
            cell.display(with: user, isCurrentUserInGroup: false)
            if tableView.isBottomReached {
                screenViewModel.action.loadmore()
            }
        }
    }
}

extension AmityForwatdChannelPickerViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return screenViewModel.dataSource.numberOfSelectedUsers()
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AmitySelectMemberListCollectionViewCell.identifier, for: indexPath)
        configure(for: cell, at: indexPath)
        return cell
    }
    
    private func configure(for cell: UICollectionViewCell, at indexPath: IndexPath) {
        if let cell = cell as? AmitySelectMemberListCollectionViewCell {
            let user = screenViewModel.dataSource.selectUser(at: indexPath)
            cell.indexPath = indexPath
            cell.display(with: user)
            cell.deleteHandler = { [weak self] indexPath in
                self?.deleteItem(at: indexPath)
            }
        }
    }
}

extension AmityForwatdChannelPickerViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: collectionView.frame.height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 0, left: 20, bottom: 0, right: 20)
    }
}

extension AmityForwatdChannelPickerViewController: AmityForwardChannelPickerScreenViewModelDelegate {
    
    func screenViewModelDidFetchUser() {
        tableView.reloadData()
        AmityEventHandler.shared.hideKTBLoading()
    }
    
    func screenViewModelDidSearchUser() {
        tableView.reloadData()
        AmityEventHandler.shared.hideKTBLoading()
    }
    
    func screenViewModelCanDone(enable: Bool) {
        doneButton?.isEnabled = enable
    }
    
    func screenViewModelDidSelectUser(title: String, isEmpty: Bool) {
        self.title = title
        collectionView.isHidden = isEmpty
        tableView.reloadData()
        collectionView.reloadData()
        selectUsersHandler?(screenViewModel.dataSource.getNewSelectedUsers(), screenViewModel.dataSource.getStoreUsers(), title, lastSearchKeyword)
    }
    
    func screenViewModelDidSetCurrentUsers(title: String, isEmpty: Bool) {
        tableView.reloadData()
    }
    
    func screenViewModelDidSetNewSelectedUsers(title: String, isEmpty: Bool, isFromAnotherTab: Bool, keyword: String) {
        // Set title if need
        self.title = title
        
        // Set keyword if need
        lastSearchKeyword = keyword
        searchBar.text = keyword
        
        // Update collection view
        collectionView.isHidden = isEmpty
        collectionView.reloadData()
        
        // Update table view
        if isFromAnotherTab {
            screenViewModel.action.updateSelectedUserInfo()
        }
        tableView.reloadData()

        // Send new selected user & latest store user (new selected user + current user) to handler of parent view controller
        selectUsersHandler?(screenViewModel.dataSource.getNewSelectedUsers(), screenViewModel.dataSource.getStoreUsers(), title, lastSearchKeyword)
    }
    
    func screenViewModelLoadingState(for state: AmityLoadingState) {
        switch state {
        case .loading:
            tableView.showLoadingIndicator()
        case .initial, .loaded:
            tableView.tableFooterView = UIView()
        }
    }
}
