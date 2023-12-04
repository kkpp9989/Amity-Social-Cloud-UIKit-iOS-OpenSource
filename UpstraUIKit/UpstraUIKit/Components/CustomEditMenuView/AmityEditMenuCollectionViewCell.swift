//
//  AmityEditMenuCollectionViewCell.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 30/11/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

class AmityEditMenuCollectionViewCell: UICollectionViewCell, Nibbable {
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var title: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override func prepareForReuse() {
        clear()
    }
    
    private func setupView() {
        // Setup container view
        containerView.backgroundColor = UIColor(hex: "#63687833", alpha: 0.2)
        containerView.layer.cornerRadius = 12
        
        // Setup title
        title.font = UIFont(name: AmityFontSet.caption.fontName, size: 10)
        title.textColor = .white
        title.numberOfLines = 1
        
        // Setup icon
        iconView.backgroundColor = .clear
    }
    
    func display(with item: AmityEditMenuItem) {
        title.text = item.title
        iconView.image = item.icon
    }
    
    func clear() {
        title.text = nil
        iconView.image = nil
    }
    
}
