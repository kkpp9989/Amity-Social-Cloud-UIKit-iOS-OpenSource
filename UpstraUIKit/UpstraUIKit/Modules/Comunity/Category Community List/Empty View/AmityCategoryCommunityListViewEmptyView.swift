//
//  AmityCategoryCommunityListViewEmptyView.swift
//  AmityUIKit
//
//  Created by Nontapat Siengsanor on 16/10/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit

class AmityCategoryCommunityListViewEmptyView: AmityView {
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var subtitleLabel: UILabel!
    
    // MARK: - Properties
    var exploreHandler: (() -> Void)?
    var createHandler: (() -> Void)?
    
    override func initial() {
        loadNibContent()
        setupView()
    }
    
    private func setupView() {
        backgroundColor = AmityColorSet.backgroundColor
        contentView.backgroundColor = AmityColorSet.backgroundColor
        
        imageView.image = AmityIconSet.emptyNewsfeed
        // [Fix defect] Change message of title
        titleLabel.text = AmityLocalizedStringSet.emptyCommunityInCategoryTitle.localizedString
        titleLabel.textColor = AmityColorSet.base.blend(.shade2)
        // [Fix defect] Set font to title style
        titleLabel.font = AmityFontSet.title
        
        // [Fix defect] Change message of subtitle
        subtitleLabel.text = AmityLocalizedStringSet.emptyCommunityInCategorySubtitle.localizedString
        subtitleLabel.textColor = AmityColorSet.base.blend(.shade2)
        subtitleLabel.font = AmityFontSet.body
    }
    
}
