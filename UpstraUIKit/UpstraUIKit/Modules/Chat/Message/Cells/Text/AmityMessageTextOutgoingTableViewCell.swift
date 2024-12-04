//
//  AmityMessageTextOutgoingTableViewCell.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 20/12/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

class AmityMessageTextOutgoingTableViewCell: AmityMessageTextTableViewCell {
    
    enum Constant {
        static let spaceOfStackWithinContainerMessageView = 4.0
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBOutlet private var stackWithinContainerMessageView: UIStackView!
    @IBOutlet private var stackMainView: UIStackView!
    @IBOutlet private var leadingTextMessageViewConstraint: NSLayoutConstraint!
    
    override func setupView() {
        super.setupView()

        stackWithinContainerMessageView.spacing = Constant.spaceOfStackWithinContainerMessageView
        textMessageView.preferredMaxLayoutWidth = stackMainView.frame.width - leadingTextMessageViewConstraint.constant - Constant.spaceOfStackWithinContainerMessageView
    }

}
