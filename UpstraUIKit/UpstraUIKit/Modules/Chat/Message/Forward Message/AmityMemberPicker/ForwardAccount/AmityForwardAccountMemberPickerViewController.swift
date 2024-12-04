//
//  AmityForwardAccountMemberPickerViewController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 4/11/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

extension AmityForwardAccountMemberPickerViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: AmityPagerTabViewController) -> IndicatorInfo {
        return IndicatorInfo(title: pageTitle)
    }
}

class AmityForwardAccountMemberPickerViewController: AmityViewController {
    
    // MARK: - Callback
    public var selectUsersHandler: ((_ newSelectedUsers: [AmitySelectMemberModel], _ storeUsers: [AmitySelectMemberModel],_ title: String, _ keyword: String) -> Void)?

    // MARK: - IBOutlet Properties
    @IBOutlet private var searchBar: UISearchBar!
    @IBOutlet private var collectionView: UICollectionView!
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var label: UILabel!
    @IBOutlet private var emptyView: UIView!
    @IBOutlet private var emptyLabel: UILabel!
    
    // MARK: - Properties
    private var screenViewModel: AmityMemberPickerScreenViewModelType!
    private var doneButton: UIBarButtonItem?
    var lastSearchKeyword: String = ""
    
    // MARK: - Custom Theme Properties [Additional]
    private var theme: ONEKrungthaiCustomTheme?
    
    var pageTitle: String?

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initial ONE Krungthai Custom theme
        theme = ONEKrungthaiCustomTheme(viewController: self)
        
        setupView()
        setupEmptyView()
        
        screenViewModel.delegate = self
        
        // Get data
        if !lastSearchKeyword.isEmpty { // Case : Have keyword -> Search user
            screenViewModel.action.searchUser(with: lastSearchKeyword)
        } else { // Case : Don't have keyword -> Get all user
            screenViewModel.action.getUsers()
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set color navigation bar by custom theme
        theme?.setBackgroundNavigationBar()
    }

    public static func make(pageTitle: String, users: [AmitySelectMemberModel] = []) -> AmityForwardAccountMemberPickerViewController {
        let viewModeel: AmityMemberPickerScreenViewModelType = AmityMemberPickerScreenViewModel()
        viewModeel.setCurrentUsers(users: users)
        let vc = AmityForwardAccountMemberPickerViewController(nibName: AmityForwardAccountMemberPickerViewController.identifier, bundle: AmityUIKitManager.bundle)
        vc.screenViewModel = viewModeel
        vc.pageTitle = pageTitle
        return vc
    }
    
    public func setNewSelectedUsers(users: [AmitySelectMemberModel], isFromAnotherTab: Bool, keyword: String) {
        screenViewModel.setNewSelectedUsers(users: users, isFromAnotherTab: isFromAnotherTab, keyword: keyword)
    }
    
    public func fetchData() {
        screenViewModel.action.clearData()
    }
    
    func setupEmptyView() {
        emptyLabel.font = AmityFontSet.bodyBold
        emptyLabel.text = "No user found"
    }
    
    func setEmptyView() {
        if screenViewModel.isSearching() {
            // Hide emptyView if there are search results, show otherwise.
            emptyView.isHidden = screenViewModel.dataSource.numberOfSearchUsers() > 0
        } else {
            // Hide emptyView if there are any users, show otherwise.
            emptyView.isHidden = screenViewModel.dataSource.numberOfAllUsers() > 0
        }
    }
}

private extension AmityForwardAccountMemberPickerViewController {
    @objc func doneTap() {
        dismiss(animated: true) { [weak self] in
            guard let strongSelf = self else { return }
//            strongSelf.selectUsersHandler?(strongSelf.screenViewModel.dataSource.getStoreUsers())
        }
    }
    
    @objc func cancelTap() {
        dismiss(animated: true)
    }
    
    func deleteItem(at indexPath: IndexPath) {
        screenViewModel.action.deselectUser(at: indexPath)
    }
}

private extension AmityForwardAccountMemberPickerViewController {
    func setupView() {
        setupNavigationBar()
        setupSearchBar()
        setupTableView()
        setupCollectionView()
    }
    
    func setupNavigationBar() {
        navigationBarType = .custom
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
            title = AmityLocalizedStringSet.selectMemberListTitle.localizedString
        } else {
            
            title = String.localizedStringWithFormat(AmityLocalizedStringSet.selectMemberListSelectedTitle.localizedString, "\(numberOfSelectedUseres)")
        }
        
        doneButton = UIBarButtonItem(title: AmityLocalizedStringSet.General.done.localizedString, style: .plain, target: self, action: #selector(doneTap))
        doneButton?.tintColor = AmityColorSet.primary
        doneButton?.isEnabled = !(numberOfSelectedUseres == 0)
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
    
    func setupSearchBar() {
        searchBar.backgroundImage = UIImage()
        searchBar.delegate = self
        searchBar.tintColor = AmityColorSet.base
        searchBar.searchTextField.font = AmityFontSet.body
        searchBar.returnKeyType = .done
        (searchBar.value(forKey: "searchField") as? UITextField)?.textColor = AmityColorSet.base
        ((searchBar.value(forKey: "searchField") as? UITextField)?.leftView as? UIImageView)?.tintColor = AmityColorSet.base.blend(.shade2)
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

extension AmityForwardAccountMemberPickerViewController: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        lastSearchKeyword = searchText
        selectUsersHandler?(screenViewModel.dataSource.getNewSelectedUsers(), screenViewModel.dataSource.getStoreUsers(), AmityLocalizedStringSet.selectMemberListTitle.localizedString, lastSearchKeyword)
        
        if lastSearchKeyword.isEmpty {
            if screenViewModel.dataSource.numberOfAllUsers() == 0 { // Case : Don't have keyword and didn't have all channel -> Get all channel
                screenViewModel.action.getUsers()
            } else { // Case : Don't have keyword but have current all channel data -> Reload tableview for show current all channel
                screenViewModel.action.updateSearchingStatus(isSearch: false)
                tableView.reloadData()
            }
        }
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else {
            return
        }
        
        lastSearchKeyword = searchText
        screenViewModel.action.searchUser(with: searchText)
    }
}

extension AmityForwardAccountMemberPickerViewController: UITableViewDelegate {
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
}

extension AmityForwardAccountMemberPickerViewController: UITableViewDataSource {
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
            let isCurrentUserInGroup = screenViewModel.dataSource.isCurrentUserInGroup(id: user.userId)
            cell.display(with: user, isCurrentUserInGroup: isCurrentUserInGroup)
            if tableView.isBottomReached {
                screenViewModel.action.loadmore()
            }
        }
    }
}

extension AmityForwardAccountMemberPickerViewController: UICollectionViewDataSource {
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

extension AmityForwardAccountMemberPickerViewController: UICollectionViewDelegateFlowLayout {
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

extension AmityForwardAccountMemberPickerViewController: AmityMemberPickerScreenViewModelDelegate {
    
    func screenViewModelDidFetchUser() {
        tableView.reloadData()
        setEmptyView()
    }
    
    func screenViewModelDidSearchUser() {
        tableView.reloadData()
        setEmptyView()
    }
    
    func screenViewModelCanDone(enable: Bool) {
        doneButton?.isEnabled = enable
    }
    
    func screenViewModelDidSelectUser(title: String, isEmpty: Bool) {
        self.title = title
        collectionView.isHidden = isEmpty
        tableView.reloadData()
        collectionView.reloadData()
        selectUsersHandler?(screenViewModel.dataSource.getNewSelectedUsers() ,screenViewModel.dataSource.getStoreUsers(), title, lastSearchKeyword)
    }
    
    func screenViewModelDidSetCurrentUsers(title: String, isEmpty: Bool) {
        tableView.reloadData()
    }
    
    func screenViewModelDidSetNewSelectedUsers(title: String, isEmpty: Bool, isFromAnotherTab: Bool, keyword: String) {
        // Set title if need
        self.title = title
        
        searchBar.text = keyword
        lastSearchKeyword = keyword
        
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
    
    func screenViewModelClearData() {
        tableView.reloadData()
        if !lastSearchKeyword.isEmpty { // Case : Have keyword -> Search user by latest search keyword
            screenViewModel.action.searchUser(with: lastSearchKeyword)
        } else { // Case : Don't have keyword
            if screenViewModel.dataSource.numberOfAllUsers() == 0 { // Case : Don't have keyword and didn't have all user -> Get all user (create viewcontroller with searching)
                screenViewModel.action.getUsers()
            } else { // Case : Case : Don't have keyword but have current all user data  -> Reload tableview for show current all user
                screenViewModel.action.updateSearchingStatus(isSearch: false)
                tableView.reloadData()
            }
        }
    }
}
