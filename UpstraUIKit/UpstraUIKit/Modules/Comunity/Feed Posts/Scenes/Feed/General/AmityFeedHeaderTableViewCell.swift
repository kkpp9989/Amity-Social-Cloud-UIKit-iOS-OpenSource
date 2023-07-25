//
//  AmityFeedHeaderTableViewCell.swift
//  AmityUIKit
//
//  Created by Nontapat Siengsanor on 21/10/2563 BE.
//  Copyright © 2563 Amity. All rights reserved.
//

import UIKit

class AmityFeedHeaderTableViewCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        contentView.backgroundColor = .groupTableViewBackground
    }
    
    func set(headerView: UIView?, postTabHeaderView: UIView?) {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        if let postTabHeaderView = postTabHeaderView {
            postTabHeaderView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(postTabHeaderView)
            if headerView != nil {
                NSLayoutConstraint.activate([
                    postTabHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    postTabHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    postTabHeaderView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor),
                ])
            } else {
                NSLayoutConstraint.activate([
                    postTabHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    postTabHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    postTabHeaderView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor),
                    postTabHeaderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                ])
            }
        }
        
        if let headerView = headerView {
            headerView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(headerView)
            NSLayoutConstraint.activate([
                headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                headerView.topAnchor.constraint(equalTo: postTabHeaderView?.bottomAnchor ?? contentView.topAnchor, constant: 8), // Add a constant space between the two views
                headerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ])
        }
    }
}
