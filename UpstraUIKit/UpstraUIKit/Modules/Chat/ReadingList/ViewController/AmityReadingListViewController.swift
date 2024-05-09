//
//  AmityReadingListViewController.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 8/12/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

protocol ReadingListDelegate: AnyObject {
    func didClose()
}

class AmityReadingListViewController: AmityViewController {
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var readCountLabel: UILabel!
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var butCloseModal: UIButton! {
        didSet {
            butCloseModal.addTarget(self, action: #selector(butActionCloseModal), for: .touchDown)
        }
    }
    
    // MARK: - Properties
    weak var delegate: ReadingListDelegate?
    private var screenViewModel: AmityReadingListScreenViewModelType!
    private var emptyView = AmitySearchEmptyView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScreenViewModle()
        setupTableView()
    }
    
    public static func make(message: AmityMessageModel) -> AmityReadingListViewController {
        let viewModel = AmityReadingListScreenViewModel(message: message)
        let vc = AmityReadingListViewController(nibName: AmityReadingListViewController.identifier, bundle: AmityUIKitManager.bundle)
        vc.screenViewModel = viewModel
        return vc
    }
    
    // MARK: - Setup viewModel
    private func setupScreenViewModle() {
        screenViewModel.delegate = self
        screenViewModel.action.fetchData()
    }
    
    // MARK: - Setup views
    private func setupView() {
        navigationBarType = .custom
        
        readCountLabel.text = "Read by 0 people"
        readCountLabel.font = AmityFontSet.bodyBold
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(butActionCloseModal))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tapGesture)
        
        bottomConstraint.constant = -386
        self.view.layoutIfNeeded()
        fadeIn()
    }
    
    private func setupTableView() {
        tableView.register(AmityReadingTableViewCell.nib, forCellReuseIdentifier: AmityReadingTableViewCell.identifier)
        tableView.separatorColor = .clear
        tableView.backgroundColor = AmityColorSet.backgroundColor
        tableView.tableFooterView = UIView()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func removeView() {
        downStatusView()
    }
}

// MARK: - Button Action
extension AmityReadingListViewController {
    
   @objc private func butActionCloseModal() {
       removeView()
    }
    
}

// MARK: - Animation Control
extension AmityReadingListViewController {
    
    func fadeIn() {
        UIView.animate(withDuration: 0.2) {
            self.view.alpha = 1
            self.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.upStatusView()
        }
    }
    
    func fadeOut() {
        UIView.animate(withDuration: 0.2) {
            self.view.alpha = 0
            self.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.delegate?.didClose()
        }
    }
    
    func upStatusView() {
        UIView.animate(withDuration: 0.2) {
            self.bottomConstraint.constant = 0
        } completion: { [weak self] _ in
            self?.fadeInView()
        }
    }
    
    func downStatusView() {
        UIView.animate(withDuration: 0.2) {
            self.bottomConstraint.constant = -386
            self.view.layoutIfNeeded()
        } completion: { [weak self] _ in
            self?.fadeOut()
        }
    }
    
    func fadeInView() {
        UIView.animate(withDuration: 1.0) {
            self.view.backgroundColor = .black.withAlphaComponent(0.5)
        }
    }
    
}

// MARK: - UITableView Delegate
extension AmityReadingListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let model = screenViewModel.dataSource.item(at: indexPath) else { return }
        AmityEventHandler.shared.userKTBDidTap(from: self, userId: model.userId)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Calculate the current scroll position and content height
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        
        // Check if the user has scrolled to the bottom
        if maximumOffset - currentOffset <= 0 {
            screenViewModel.action.loadMore()
        }
    }
}

// MARK: - UITableView DataSource
extension AmityReadingListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return screenViewModel.dataSource.numberOfKeyword()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AmityReadingTableViewCell.identifier, for: indexPath)
        configure(for: cell, at: indexPath)
        return cell
    }
    
    private func configure(for cell: UITableViewCell, at indexPath: IndexPath) {
        if let cell = cell as? AmityReadingTableViewCell {
            if let user = screenViewModel.dataSource.item(at: indexPath) {
                cell.display(with: user)
            }
        }
    }
}

extension AmityReadingListViewController: AmityReadingListScreenViewModelDelegate {
    func screenViewModelDidFetchSuccess(_ viewModel: AmityReadingListScreenViewModelType) {
        emptyView.removeFromSuperview()
        tableView.reloadData()
        AmityEventHandler.shared.hideKTBLoading()
        
        let readCount = screenViewModel.dataSource.numberOfKeyword()
        readCountLabel.text = "Read by \(readCount) people"
    }
    
    func screenViewModelDidClearText(_ viewModel: AmityReadingListScreenViewModelType) {
        emptyView.removeFromSuperview()
        tableView.reloadData()
        AmityEventHandler.shared.hideKTBLoading()
    }
    
    func screenViewModelDidFetchNotFound(_ viewModel: AmityReadingListScreenViewModelType) {
        tableView.setEmptyView(view: emptyView)
        tableView.reloadData()
        AmityEventHandler.shared.hideKTBLoading()
    }
    
    func screenViewModel(_ viewModel: AmityReadingListScreenViewModelType, loadingState: AmityLoadingState) {
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
