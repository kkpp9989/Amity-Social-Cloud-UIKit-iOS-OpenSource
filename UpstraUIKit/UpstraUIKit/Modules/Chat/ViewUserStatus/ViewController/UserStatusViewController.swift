//
//  UserStatusViewController.swift
//  AmityUIKit
//
//  Created by PrInCeInFiNiTy on 10/4/23.
//  Copyright © 2023 Amity. All rights reserved.
//

import UIKit

class UserStatusViewController: UIViewController, Nibbable {
    
    weak var delegate: UserStatusDelegate?
    @IBOutlet weak var tableviewStatus: UITableView!
    @IBOutlet weak var butCloseModal: UIButton! {
        didSet {
            butCloseModal.addTarget(self, action: #selector(butActionCloseModal), for: .touchDown)
        }
    }
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var viewModel = UserStatusViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupView()
    }

}

// MARK: - Setup Control
extension UserStatusViewController {
    
    func setupView() {
        bottomConstraint.constant = -386
        self.view.layoutIfNeeded()
        fadeIn()
    }
    
    func removeView() {
        downStatusView()
    }
    
    func setupTableView() {
        tableviewStatus.register(StatusTableViewCell.nib, forCellReuseIdentifier: StatusTableViewCell.identifier)
    }
    
}

// MARK: - Button Action
extension UserStatusViewController {
    
   @objc private func butActionCloseModal() {
       removeView()
    }
    
}

// MARK: - Animation Control
extension UserStatusViewController {
    
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
            self.view.layoutIfNeeded()
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
    
}

// MARK: - UITableview DataSource
extension UserStatusViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.heightForRowAt()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:StatusTableViewCell = tableviewStatus.dequeueReusableCell(withIdentifier: StatusTableViewCell.identifier, for: indexPath) as! StatusTableViewCell
        cell.setStatusName(viewModel.cellForRowAtData(indexPath))
        cell.imgArrow.isHidden = viewModel.isSelectStatus(indexPath)
        return cell
    }
    
}

// MARK: - UITableview Delegate
extension UserStatusViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 1:
            viewModel.typeSelect = .DO_NOT_DISTURB
        case 2:
            viewModel.typeSelect = .IN_THE_OFFICE
        case 3:
            viewModel.typeSelect = .WORK_FROM_HOME
        case 4:
            viewModel.typeSelect = .IN_A_MEETING
        case 5:
            viewModel.typeSelect = .ON_LEAVE
        case 6:
            viewModel.typeSelect = .OUT_SICK
        default:
            viewModel.typeSelect = .AVAILABLE
        }
        AmityUIKitManagerInternal.shared.userStatus = viewModel.typeSelect
        removeView()
    }
    
}
