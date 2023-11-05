//
//  AmityMessagesSearchViewController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 10/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

class AmityMessagesSearchViewController: AmityViewController, IndicatorInfoProvider {
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var tableView: UITableView!
    
    // MARK: - Properties
    private var screenViewModel: AmityMessagesSearchScreenViewModelType!
    private var pageTitle: String?
    private var emptyView = AmitySearchEmptyView()
    private var keyword: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScreenViewModle()
        setupTableView()
    }
    
    public static func make(title: String) -> AmityMessagesSearchViewController {
        let viewModel = AmityMessagesSearchScreenViewModel()
        let vc = AmityMessagesSearchViewController(nibName: AmityMessagesSearchViewController.identifier, bundle: AmityUIKitManager.bundle)
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
        tableView.register(AmityMessageSearchTableViewCell.nib, forCellReuseIdentifier: AmityMessageSearchTableViewCell.identifier)
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
extension AmityMessagesSearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let model = screenViewModel.dataSource.item(at: indexPath) else { return }
        AmityChannelEventHandler.shared.channelWithJumpMessageDidTap(from: self, channelId: model.channelObjc.channelId, subChannelId: model.channelObjc.object.defaultSubChannelId, messageId: model.messageObjc.messageID ?? "")
    }
    
    func tableView(_ tablbeView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.isBottomReached {
            screenViewModel.action.loadMore()
        }
    }
    
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
extension AmityMessagesSearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return screenViewModel.dataSource.numberOfKeyword()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AmityMessageSearchTableViewCell.identifier, for: indexPath)
        configure(for: cell, at: indexPath)
        return cell
    }
    
    private func configure(for cell: UITableViewCell, at indexPath: IndexPath) {
        if let cell = cell as? AmityMessageSearchTableViewCell, let message = screenViewModel.dataSource.item(at: indexPath) {
            cell.display(with: message, keyword: keyword)
        }
    }
}

extension AmityMessagesSearchViewController: AmityMessagesSearchScreenViewModelDelegate {
    func screenViewModelDidSearch(_ viewModel: AmityMessagesSearchScreenViewModelType) {
        emptyView.removeFromSuperview()
        tableView.reloadData()
    }
    
    func screenViewModelDidClearText(_ viewModel: AmityMessagesSearchScreenViewModelType) {
        emptyView.removeFromSuperview()
        tableView.reloadData()
    }
    
    func screenViewModelDidSearchNotFound(_ viewModel: AmityMessagesSearchScreenViewModelType) {
        tableView.setEmptyView(view: emptyView)
        tableView.reloadData()
    }
    
    func screenViewModel(_ viewModel: AmityMessagesSearchScreenViewModelType, loadingState: AmityLoadingState) {
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

extension AmityMessagesSearchViewController: AmityMessagesSearchScreenViewModelAction {
    func clearData() {
        screenViewModel.action.clearData()
    }
    
    func loadMore() {
        screenViewModel.action.loadMore()
    }
    
    func search(withText text: String?) {
        guard let keyword = text else { return }
        if keyword != self.keyword {
//            screenViewModel.action.clearData()
        }
        if !keyword.isEmpty {
            screenViewModel.action.search(withText: text)
            self.keyword = keyword
        }
    }
}
