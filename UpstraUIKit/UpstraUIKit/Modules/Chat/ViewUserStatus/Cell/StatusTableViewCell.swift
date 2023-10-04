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
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setStatusName(_ statusName: String) {
        lblStatusName.text = statusName
    }
    
}
