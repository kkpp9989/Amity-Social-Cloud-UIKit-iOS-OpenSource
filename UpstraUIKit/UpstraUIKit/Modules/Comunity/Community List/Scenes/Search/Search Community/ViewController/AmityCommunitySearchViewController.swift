//
//  AmityCommunitySearchViewController.swift
//  AmityUIKit
//
//  Created by Sarawoot Khunsri on 26/4/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

import UIKit

final class AmityCommunitySearchViewController: AmityViewController, IndicatorInfoProvider {

    // MARK: - IBOutlet Properties
    @IBOutlet private var tableView: UITableView!
    
    // MARK: - Properties
    private var screenViewModel: AmityCommunitySearchScreenViewModelType!
    private var emptyView = AmitySearchEmptyView()
    
    private var pageTitle: String?
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupTableView()
        setupScreenViewModle()
    }
    
    static func make(title: String) -> AmityCommunitySearchViewController {
        let communityListRepositoryManager = AmityCommunityListRepositoryManager()
        let viewModel = AmityCommunitySearchScreenViewModel(communityListRepositoryManager: communityListRepositoryManager)
        let vc = AmityCommunitySearchViewController(nibName: AmityCommunitySearchViewController.identifier, bundle: AmityUIKitManager.bundle)
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
        tableView.register(cell: AmitySearchCommunityTableViewCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorColor = .clear
    }
    
    func indicatorInfo(for pagerTabStripController: AmityPagerTabViewController) -> IndicatorInfo {
        return IndicatorInfo(title: pageTitle)
    }
}

extension AmityCommunitySearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let communityId = screenViewModel.dataSource.item(at: indexPath)?.communityId else { return }
        AmityEventHandler.shared.communityDidTap(from: self, communityId: communityId)
    }
    
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
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

extension AmityCommunitySearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return screenViewModel.dataSource.numberOfCommunity()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: AmitySearchCommunityTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        guard let community = screenViewModel.dataSource.item(at: indexPath) else { return UITableViewCell() }
        cell.display(with: community)
        cell.delegate = self
        return cell
    }
}

extension AmityCommunitySearchViewController: AmitySearchCommunityTableViewCellDelegate {
    func cellDidTapOnAvatar(_ cell: AmitySearchCommunityTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell), let community = screenViewModel.dataSource.item(at: indexPath) else { return }
        AmityEventHandler.shared.communityDidTap(from: self, communityId: community.communityId)
    }
}

extension AmityCommunitySearchViewController: AmityCommunitySearchScreenViewModelDelegate {
    func screenViewModelDidSearch(_ viewModel: AmityCommunitySearchScreenViewModelType) {
        emptyView.removeFromSuperview()
    }
    
    func screenViewModelDidClearText(_ viewModel: AmityCommunitySearchScreenViewModelType) {
        emptyView.removeFromSuperview()
    }
    
    func screenViewModelDidSearchNotFound(_ viewModel: AmityCommunitySearchScreenViewModelType) {
        tableView.setEmptyView(view: emptyView)
    }
    
    func screenViewModel(_ viewModel: AmityCommunitySearchScreenViewModelType, loadingState: AmityLoadingState) {
        switch loadingState {
        case .initial:
            break
        case .loading:
            emptyView.removeFromSuperview()
            tableView.showLoadingIndicator()
            tableView.reloadData()
        case .loaded:
            tableView.tableFooterView = UIView()
            tableView.reloadData()
        }
    }
}

extension AmityCommunitySearchViewController :AmitySearchViewControllerAction {
    func search(with text: String?) {
        screenViewModel.action.search(withText: text)
    }
}
