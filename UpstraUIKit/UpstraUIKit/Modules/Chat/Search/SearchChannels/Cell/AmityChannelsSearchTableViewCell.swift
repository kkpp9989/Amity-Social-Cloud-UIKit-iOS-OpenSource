//
//  AmityChannelsSearchTableViewCell.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 16/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

public protocol AmityChannelsSearchTableViewCellDelegate: AnyObject {
    func didJoinPerformAction(_ indexPath: IndexPath)
}

class AmityChannelsSearchTableViewCell: UITableViewCell, Nibbable {
    
    @IBOutlet private var avatarView: AmityAvatarView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var joinButton: UIButton!
    
    var delegate: AmityChannelsSearchTableViewCellDelegate?
    var indexPath: IndexPath?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        joinButton.isHidden = true
        titleLabel.text = ""
    }
    
    private func setupView() {
        contentView.backgroundColor = AmityColorSet.backgroundColor
        selectionStyle = .none
        
        titleLabel.font = AmityFontSet.title
        titleLabel.textColor = AmityColorSet.base
        
        avatarView.placeholder = AmityIconSet.defaultGroupChat
        
        joinButton.titleLabel?.font = AmityFontSet.title
        joinButton.setTitle(    AmityLocalizedStringSet.communityDetailJoinButton.localizedString
                                , for: .normal)
        joinButton.setTitleColor(AmityColorSet.primary, for: .normal)
    }
    
    func display(with data: AmityChannelModel, keyword: String) {
        let highlightText = highlightKeyword(in: data.displayName, keyword: keyword, highlightColor: AmityColorSet.primary)
        titleLabel.attributedText = highlightText
        avatarView.setImage(withImageURL: data.avatarURL, placeholder: AmityIconSet.defaultGroupChat)
        
//        joinButton.isHidden = data.channelType == .community ? false : true
    }
    
    // MARK: - Perform Action
    @IBAction func openJoinTapAction(_ sender: UIButton) {
        guard let indexPath = indexPath else { return }
        delegate?.didJoinPerformAction(indexPath)
    }
    
    // MARK: - String Helper
    func highlightKeyword(in text: String, keyword: String, highlightColor: UIColor) -> NSAttributedString {
        // Create an attributed string with the original text
        let attributedText = NSMutableAttributedString(string: text)
        
        // Define the attributes for the keyword's appearance (e.g., text color)
        let keywordAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: highlightColor
        ]
        
        // Use a case-insensitive search to find all occurrences of the keyword in the text
        let range = (text as NSString).range(of: keyword, options: .caseInsensitive)
        
        // If the keyword is found, apply the keywordAttributes to the range
        if range.location != NSNotFound {
            attributedText.addAttributes(keywordAttributes, range: range)
        }
        
        return attributedText
    }
}