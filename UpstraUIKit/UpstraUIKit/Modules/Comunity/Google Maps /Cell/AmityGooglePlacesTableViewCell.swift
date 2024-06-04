//
//  AmityGooglePlacesTableViewCell.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 31/5/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import UIKit
import GooglePlaces

class AmityGooglePlacesTableViewCell: UITableViewCell, Nibbable {
    
    // Define the labels
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AmityFontSet.bodyBold
        label.textColor = AmityColorSet.base
        return label
    }()
    
    private let descLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AmityFontSet.body
        label.textColor = AmityColorSet.base.blend(.shade3)
        label.numberOfLines = 2 // Allows for multiline description
        return label
    }()
    
    // Initializer
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupViews()
    }
    
    // Add the labels to the content view and setup constraints
    private func setupViews() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(descLabel)
        
        NSLayoutConstraint.activate([
            // Title Label Constraints
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Description Label Constraints
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            descLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    // Public method to configure the cell
    func configure(withData place: GMSAutocompleteSuggestion) {
        titleLabel.attributedText = place.placeSuggestion?.attributedPrimaryText
        descLabel.attributedText = place.placeSuggestion?.attributedSecondaryText
    }
}
