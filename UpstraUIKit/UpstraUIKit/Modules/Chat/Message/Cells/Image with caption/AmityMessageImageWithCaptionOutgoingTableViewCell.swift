//
//  AmityMessageImageWithCaptionOutgoingTableViewCell.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 16/1/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import UIKit

final class AmityMessageImageWithCaptionOutgoingTableViewCell: AmityMessageImageWithCaptionTableViewCell {
    
    @IBOutlet private weak var drimView: UIView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    
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

