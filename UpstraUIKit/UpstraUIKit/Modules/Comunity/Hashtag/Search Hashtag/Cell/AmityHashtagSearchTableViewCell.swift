//
//  AmityHashtagSearchTableViewCell.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 19/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

class AmityHashtagSearchTableViewCell: UITableViewCell, Nibbable {
    
    static let defaultHeight: CGFloat = 56.0
    
    @IBOutlet private var keywordLabel: UILabel!
    
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
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        keywordLabel.text = ""
    }
    
    func display(with community: AmityHashtagModel) {
        keywordLabel.text = "#\(community.text ?? "")"
    }
}
