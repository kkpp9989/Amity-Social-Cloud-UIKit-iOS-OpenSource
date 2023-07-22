//
//  AmityHashtagTableViewCell.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 19/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

public final class AmityHashtagTableViewCell: UITableViewCell, Nibbable {

    // MARK: - IBOutlet Properties
    @IBOutlet private var keywordLabel: UILabel!
    @IBOutlet private var postCountLabel: UILabel!
    
    public static let height: CGFloat = 65.0
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override public func prepareForReuse() {
        super.prepareForReuse()
        
        keywordLabel.text = ""
    }
    
    public func display(with model: AmityHashtagModel) {
        keywordLabel.text = model.text
        postCountLabel.text = model.count?.formatUsingAbbrevation()
    }
}

// MARK:- Private methods
private extension AmityHashtagTableViewCell {
    func setupView() {
        selectionStyle = .none
        backgroundColor = AmityColorSet.backgroundColor
        contentView.backgroundColor = AmityColorSet.backgroundColor
        
        setupKeyword()
        setupPostCount()
    }
    
    func setupKeyword() {
        keywordLabel.text = ""
        keywordLabel.font = AmityFontSet.bodyBold
        keywordLabel.textColor = AmityColorSet.base
    }
    
    func setupPostCount() {
        postCountLabel.text = ""
        postCountLabel.font = AmityFontSet.caption
        postCountLabel.textColor = AmityColorSet.base.blend(.shade3)
    }
}
