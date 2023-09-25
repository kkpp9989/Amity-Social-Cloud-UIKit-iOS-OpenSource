//
//  NotificationTrayTableViewCell.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 20/9/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

class NotificationTrayTableViewCell: UITableViewCell, Nibbable {
    
    @IBOutlet private weak var avatarView: AmityAvatarView!
    @IBOutlet private weak var descLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        backgroundColor = AmityColorSet.backgroundColor
        contentView.backgroundColor = AmityColorSet.backgroundColor
        descLabel.font = AmityFontSet.bodyBold
        descLabel.textColor = AmityColorSet.base
        descLabel.numberOfLines = 0
        dateLabel.font = AmityFontSet.caption
        dateLabel.textColor = AmityColorSet.base.blend(.shade3)
    }
    
    func configure(model: NotificationTray) {
        avatarView.setImage(withImageURL: model.imageURL, placeholder: AmityIconSet.defaultAvatar)
        avatarView.placeholderPostion = .fullSize
        descLabel.text = model.description
        dateLabel.text = relativeTime(from: model.lastUpdate)
        
        if model.hasRead {
            contentView.backgroundColor = .white
        } else {
            contentView.backgroundColor = UIColor(hex: "F0FBFF")
        }
    }
    
    func relativeTime(from timestamp: Int) -> String {
        let currentTimestamp = Int(Date().timeIntervalSince1970)
        let timeDifference = currentTimestamp - (timestamp / 1000)

        if timeDifference < 60 {
            return "now"
        } else if timeDifference < 3600 {
            let minutes = timeDifference / 60
            return "\(minutes)m"
        } else if timeDifference < 86400 {
            let hours = timeDifference / 3600
            return "\(hours)h"
        } else if timeDifference < 604800 {
            let days = timeDifference / 86400
            return "\(days)d"
        } else if timeDifference < 2419200 { // 4 weeks
            let weeks = timeDifference / 604800
            return "\(weeks)w"
        } else if timeDifference < 29030400 { // 11 months
            let months = timeDifference / 2419200
            return "\(months)m"
        } else {
            let years = timeDifference / 29030400
            return "\(years)y"
        }
    }
}
