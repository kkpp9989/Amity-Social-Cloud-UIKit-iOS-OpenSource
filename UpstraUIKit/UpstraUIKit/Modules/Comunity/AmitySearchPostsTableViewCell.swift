//
//  AmitySearchPostsTableViewCell.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 12/4/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import UIKit

class AmitySearchPostsTableViewCell: UITableViewCell, Nibbable {
    
    static let defaultHeight: CGFloat = 56.0
    
    @IBOutlet private var keywordLabel: UILabel!
    @IBOutlet private var keywordCountLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    private func setupView() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        keywordLabel.font = AmityFontSet.bodyBold
        keywordLabel.textColor = AmityColorSet.base
        keywordLabel.text = ""
        
        keywordCountLabel.font = AmityFontSet.caption
        keywordCountLabel.textColor = AmityColorSet.base.blend(.shade3)
        keywordCountLabel.text = ""
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        keywordLabel.text = ""
        keywordCountLabel.text = ""
    }
    
    func display(with community: AmityHashtagModel) {
        keywordLabel.text = "#\(community.text ?? "")"
        keywordCountLabel.text = "\(community.count?.formatUsingAbbrevation() ?? "0") posts"
    }
}
