//
//  AmityMemberSearchViewController.swift
//  AmityUIKit
//
//  Created by Hamlet on 11.05.21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit

final class AmityMemberSearchViewController: AmityViewController, IndicatorInfoProvider {
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var tableView: UITableView!
    
    // MARK: - Properties
    private var pageTitle: String?
    private var screenViewModel: AmityMemberSearchScreenViewModelType!
    private var emptyView = AmitySearchEmptyView()
    private var keyword: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupTableView()
        setupScreenViewModle()
    }
    
    public static func make(title: String) -> AmityMemberSearchViewController {
        let memberListRepositoryManager = AmityMemberListRepositoryManager()
        
        let viewModel = AmityMemberSearchScreenViewModel(memberListRepositoryManager: memberListRepositoryManager)
        
        let vc = AmityMemberSearchViewController(nibName: AmityMemberSearchViewController.identifier, bundle: AmityUIKitManager.bundle)
        
        vc.screenViewModel = viewModel
        vc.pageTitle = title
        return vc
    }
    
    // MARK: - Setup viewModel
    private func setupScreenViewModle() {
        screenViewModel.delegate = self
    }
    
    // MARK: - Setup views
    private func setupView() {
        navigationBarType = .custom
    }
    
    private func setupTableView() {
        tableView.register(AmitySearchMemberTableViewCell.nib, forCellReuseIdentifier: AmitySearchMemberTableViewCell.identifier)
        tableView.separatorColor = .clear
        tableView.backgroundColor = AmityColorSet.backgroundColor
        tableView.tableFooterView = UIView()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func indicatorInfo(for pagerTabStripController: AmityPagerTabViewController) -> IndicatorInfo {
        return IndicatorInfo(title: pageTitle)
    }
}

// MARK: - UITableView Delegate
extension AmityMemberSearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let model = screenViewModel.dataSource.item(at: indexPath) else { return }
        AmityEventHandler.shared.userDidTap(from: self, userId: model.userId)
    }
    
//    func tableView(_ tablbeView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        if tableView.isBottomReached {
//            screenViewModel.action.loadMore()
//        }
//    }
    
    /* [Fix-defect] Change check is bottom reached of table view by scrollViewDidScroll in UITableViewDelegate instead */
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Calculate the current scroll position and content height
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        // Check if the user has scrolled to the bottom
        if maximumOffset - currentOffset <= 0 {
            // User has reached the bottom of the table view
            // You can load more data or perform any action you need
            screenViewModel.action.loadMore()
        }
    }
}

// MARK: - UITableView DataSource
extension AmityMemberSearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return screenViewModel.dataSource.numberOfmembers()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AmitySearchMemberTableViewCell.identifier, for: indexPath)
        configure(for: cell, at: indexPath)
        return cell
    }
    
    private func configure(for cell: UITableViewCell, at indexPath: IndexPath) {
        if let cell = cell as? AmitySearchMemberTableViewCell, let member = screenViewModel.dataSource.item(at: indexPath) {
            cell.delegate = self
            cell.display(with: member)
        }
    }
}

extension AmityMemberSearchViewController: AmityMemberSearchScreenViewModelDelegate {
    func screenViewModelDidSearch(_ viewModel: AmityMemberSearchScreenViewModelType) {
        emptyView.removeFromSuperview()
        tableView.reloadData()
    }
    
    func screenViewModelDidClearText(_ viewModel: AmityMemberSearchScreenViewModelType) {
        emptyView.removeFromSuperview()
        tableView.reloadData()
    }
    
    func screenViewModelDidSearchNotFound(_ viewModel: AmityMemberSearchScreenViewModelType) {
        tableView.setEmptyView(view: emptyView)
        tableView.reloadData()
    }
    
    func screenViewModel(_ viewModel: AmityMemberSearchScreenViewModelType, loadingState: AmityLoadingState) {
        switch loadingState {
        case .initial:
            break
        case .loading:
            emptyView.removeFromSuperview()
            tableView.showLoadingIndicator()
        case .loaded:
            tableView.tableFooterView = UIView()
        }
    }
}

extension AmityMemberSearchViewController: AmitySearchViewControllerAction {
    func search(with text: String?) {
        guard let keyword = text else { return }
//        print("[Search][Channel][Account] newKeyword: \(keyword) | currentKeyword: \(self.keyword)")
        if keyword != self.keyword {
            clearData()
        } else {
            return
        }
        
        if !keyword.isEmpty {
            screenViewModel.action.search(withText: text)
            self.keyword = keyword
        }
    }
    
    func clearData() {
        self.keyword = ""
        screenViewModel.action.clearData()
    }
}

extension AmityMemberSearchViewController: AmitySearchMemberTableViewCellDelegate {
    func cellDidTapOnAvatar(_ cell: AmitySearchMemberTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell), let model = screenViewModel.dataSource.item(at: indexPath) else { return }
        AmityEventHandler.shared.userDidTap(from: self, userId: model.userId)
    }
}
