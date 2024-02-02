//
//  AmityPreviewSelectedViewController.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 1/2/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import UIKit

class AmityPreviewSelectedFromPickerViewController: AmityViewController {

    // MARK: - IBOutlet Properties
    @IBOutlet private weak var tableView: UITableView!
    private var doneButton: UIBarButtonItem?
    
    // MARK: - ScreenViewModel
    private var screenViewModel: AmityPreviewSelectedFromPickerScreenViewModelType!
    
    // MARK: - IBOutlet Properties
    var pageTitle: String?
    private let debouncer = Debouncer(delay: 0.3)

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        screenViewModel.delegate = self
        setupView()
        setupNavigationBar()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    public static func make(pageTitle: String, selectedData: [AmitySelectMemberModel] = [], broadcastMessage: AmityBroadcastMessageCreatorModel) -> AmityPreviewSelectedFromPickerViewController {
        let viewModel: AmityPreviewSelectedFromPickerScreenViewModelType = AmityPreviewSelectedFromPickerScreenViewModel(selectedData: selectedData, broadcastMessage: broadcastMessage)
        let vc = AmityPreviewSelectedFromPickerViewController(nibName: AmityPreviewSelectedFromPickerViewController.identifier, bundle: AmityUIKitManager.bundle)
        vc.screenViewModel = viewModel
        vc.pageTitle = pageTitle
        return vc
    }
    
    private func setupView() {
        /* Setup tableview */
        // Setup style
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag
        tableView.estimatedRowHeight = 1
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = AmityColorSet.backgroundColor
        // Setup cell
        tableView.register(AmityPreviewSelectedDataFromPickerTableViewCell.nib, forCellReuseIdentifier: AmityPreviewSelectedDataFromPickerTableViewCell.identifier)
        // Setup delegate & datasource
        tableView.dataSource = self
    }
    
    private func setupNavigationBar() {
        /* Setup navigation bar */
        // Setup title
        title = pageTitle
        // Setup button
        doneButton = UIBarButtonItem(title: isLastViewController ? AmityLocalizedStringSet.General.send.localizedString : AmityLocalizedStringSet.General.next.localizedString, style: .plain, target: self, action: #selector(doneTap))
        doneButton?.tintColor = AmityColorSet.primary
        doneButton?.isEnabled = !(screenViewModel.dataSource.numberOfDatas() == 0)
        doneButton?.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .normal)
        doneButton?.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .disabled)
        doneButton?.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body], for: .selected)
        navigationItem.rightBarButtonItem = doneButton
    }

}

// MARK: - Action
extension AmityPreviewSelectedFromPickerViewController {
    @objc func doneTap() {
        AmityEventHandler.shared.showKTBLoading()
        screenViewModel.action.sendBroadcastMessage()
    }
}

// MARK: - TableView Datasource
extension AmityPreviewSelectedFromPickerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AmityPreviewSelectedDataFromPickerTableViewCell.identifier, for: indexPath)
        configure(tableView, for: cell, at: indexPath)
        return cell
    }
    
    private func configure(_ tableView: UITableView, for cell: UITableViewCell, at indexPath: IndexPath) {
        if let cell = cell as? AmityPreviewSelectedDataFromPickerTableViewCell {
            guard let data = screenViewModel.dataSource.data(at: indexPath.row) else { return }
            cell.display(with: data)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return screenViewModel.dataSource.numberOfDatas()
    }
}

// MARK: - ScreenViewModel Delegate
extension AmityPreviewSelectedFromPickerViewController: AmityPreviewSelectedFromPickerScreenViewModelDelegate {
    func screenViewModelDidSendBroadcastMessage(isSuccess: Bool) {
        AmityEventHandler.shared.hideKTBLoading()

        if isSuccess {
            AmityHUD.show(.success(message: "Broadcast Sent"))
            navigationController?.popToRootViewController(animated: true) // Back to root view controller if pushed view controller
        } else {
            AmityHUD.show(.success(message: "Broadcast Failed"))
        }
    }
}

