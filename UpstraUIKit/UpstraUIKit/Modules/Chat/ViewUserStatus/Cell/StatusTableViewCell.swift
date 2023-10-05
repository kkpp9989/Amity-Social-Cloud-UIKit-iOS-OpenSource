//
//  StatusTableViewCell.swift
//  AmityUIKit
//
//  Created by PrInCeInFiNiTy on 10/5/23.
//  Copyright © 2023 Amity. All rights reserved.
//

import UIKit

class StatusTableViewCell: UITableViewCell, Nibbable {
    
    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet weak var lblStatusName: UILabel!
    @IBOutlet weak var imgArrow: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupView()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupView() {
        lblStatusName.font = AmityFontSet.bodyBold
    }
    
    func setStatusName(_ statusName: String) {
        imgIcon.image = setImageFromStatus(statusName)
        lblStatusName.text = statusName
    }
    
    private func setImageFromStatus(_ statusName: String) -> UIImage {
        switch statusName {
        case "Available":
            return AmityIconSet.Chat.iconAvailable ?? UIImage()
        case "Do not disturb":
            return AmityIconSet.Chat.iconDoNotDisturb ?? UIImage()
        case "In the office":
            return AmityIconSet.Chat.iconInTheOffice ?? UIImage()
        case "Work from home":
            return AmityIconSet.Chat.iconWorkFromHome ?? UIImage()
        case "In a meeting":
            return AmityIconSet.Chat.iconInAMeeting ?? UIImage()
        case "On leave":
            return AmityIconSet.Chat.iconOnLeave ?? UIImage()
        case "Out sick":
            return AmityIconSet.Chat.iconOutSick ?? UIImage()
        default:
            return UIImage()
        }
    }
    
}
