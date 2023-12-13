//
//  AmityPendingMembersActionTableViewCell.swift
//  Amity
//
//  Created by Sarawoot Khunsri on 7/4/2564 BE.
//  Copyright © 2564 BE Amity. All rights reserved.
//

import UIKit

protocol AmityPendingMembersActionCellDelegate: AnyObject {
    func performAction(_ cell: AmityPendingMembersActionCellProtocol, action: AmityPendingMembersAction)
}

enum AmityPendingMembersAction {
    case tapAccept
    case tapDecline
}

protocol AmityPendingMembersActionCellProtocol: UITableViewCell {
    var delegate: AmityPendingMembersActionCellDelegate? { get set }
    var post: AmityPostModel? { get }
    
    func updatePost(withPost post: AmityPostModel)
}

final class AmityPendingMembersActionTableViewCell: UITableViewCell, Nibbable, AmityPendingMembersActionCellProtocol {
    
    weak var delegate: AmityPendingMembersActionCellDelegate?
    private(set) var post: AmityPostModel?
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var separatorView: UIView!
    @IBOutlet private var acceptButton: UIButton!
    @IBOutlet private var declineButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
        setupAcceptButton()
        setupDeclineButton()
    }
    
    func updatePost(withPost post: AmityPostModel) {
        self.post = post
    }
    
    // MARK: - Setup views
    private func setupView() {
        backgroundColor = AmityColorSet.backgroundColor
        contentView.backgroundColor = AmityColorSet.backgroundColor
        selectionStyle = .none
        separatorView.backgroundColor = AmityColorSet.base.blend(.shade4)
    }
    
    private func setupAcceptButton()  {
        acceptButton.setTitle(AmityLocalizedStringSet.General.accept.localizedString, for: .normal)
        acceptButton.setTitleColor(AmityColorSet.baseInverse, for: .normal)
        acceptButton.titleLabel?.font = AmityFontSet.bodyBold
        acceptButton.layer.cornerRadius = 4
        acceptButton.backgroundColor = AmityColorSet.primary
    }
    
    private func setupDeclineButton() {
        declineButton.setTitle(AmityLocalizedStringSet.General.decline.localizedString, for: .normal)
        declineButton.setTitleColor(AmityColorSet.base, for: .normal)
        declineButton.titleLabel?.font = AmityFontSet.bodyBold
        declineButton.layer.cornerRadius = 4
        declineButton.layer.borderWidth = 1
        declineButton.layer.borderColor = AmityColorSet.base.blend(.shade3).cgColor
    }

}

// MARK: - Action
private extension AmityPendingMembersActionTableViewCell {
    
    @IBAction func acceptTap() {
        acceptButton.isEnabled = false
        
        // Dispatch a task to re-enable the button after 2 seconds (2000 milliseconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.acceptButton.isEnabled = true
        }
        delegate?.performAction(self, action: .tapAccept)
    }
    
    @IBAction func declineTap() {
        declineButton.isEnabled = false
        
        // Dispatch a task to re-enable the button after 2 seconds (2000 milliseconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.declineButton.isEnabled = true
        }
        delegate?.performAction(self, action: .tapDecline)
    }
    
}
