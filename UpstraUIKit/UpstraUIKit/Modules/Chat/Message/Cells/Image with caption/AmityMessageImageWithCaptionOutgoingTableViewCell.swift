//
//  AmityMessageImageWithCaptionOutgoingTableViewCell.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 16/1/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import UIKit

final class AmityMessageImageWithCaptionOutgoingTableViewCell: AmityMessageImageWithCaptionTableViewCell {
    
    enum Constant {
        static let spaceOfStackWithinContainerMessageView = 4.0
    }
    
    @IBOutlet private weak var stackMainView: UIStackView!
    @IBOutlet private weak var stackWithinContainerMessageView: UIStackView!
    @IBOutlet private weak var drimView: UIView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var leadingTextCaptionViewConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override func setupView() {
        super.setupView()
        drimView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
    
    override func display(message: AmityMessageModel) {
        
        if !message.isDeleted {
            switch message.syncState {
            case .syncing:
                activityIndicatorView.startAnimating()
                drimView.isHidden = false
            case .synced, .default, .error:
                activityIndicatorView.stopAnimating()
                drimView.isHidden = true
            @unknown default:
                break
            }
        }
        
        super.display(message: message)
    }
    
}

