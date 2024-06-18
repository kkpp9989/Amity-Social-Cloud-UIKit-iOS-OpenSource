//
//  AmityLocationTableViewCell.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 5/6/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import UIKit

class AmityLocationTableViewCell: AmityMessageTableViewCell {
    
    enum Constant {
        static let maximumLines: Int = 0
        static let textMessageFont = AmityFontSet.body
        static let spaceOfStackWithinContainerMessageView = 4.0
    }
    
    @IBOutlet weak var addressLabel: AmityExpandableLabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
//        messageImageView.image = AmityIconSet.defaultMessageImage
        messageImageView.contentMode = .scaleAspectFill
        addressLabel.text = nil
    }
    
    func setupView() {
        // Setup text caption view
        addressLabel.text = ""
        addressLabel.textAlignment = .left
        addressLabel.numberOfLines = Constant.maximumLines
        addressLabel.font = Constant.textMessageFont
        addressLabel.backgroundColor = .clear
        
        // Setup image view
        messageImageView.image = AmityIconSet.Chat.iconLocationPlaceholder
        messageImageView.contentMode = .scaleAspectFill
        messageImageView.layer.cornerRadius = 4
        let tapGesuter = UITapGestureRecognizer(target: self, action: #selector(imageViewTap))
        tapGesuter.numberOfTouchesRequired = 1
        contentView.isUserInteractionEnabled = true
        contentView.addGestureRecognizer(tapGesuter)
    }
    
    override func display(message: AmityMessageModel) {
        super.display(message: message)
        
        if message.isOwner {
            containerView.backgroundColor = AmityColorSet.messageBubble
        } else {
            containerView.backgroundColor = AmityColorSet.messageBubbleInverse
        }
        
        // Display text
        if let tableBoundingWidth = tableBoundingWidth {
            addressLabel.preferredMaxLayoutWidth = actualWidth(for: message, boundingWidth: tableBoundingWidth)
        }
        
        var locationText: String = ""
        if let location  = message.data?["location"] as? [String: Any], let title = location["name"] as? String, let address = location["address"] as? String {
            locationText = "\(title)\n\(address)"
        } else if let location  = message.data?["location"] as? [String: Any], let lat = location["lat"] as? Double, let long = location["lng"] as? Double {
            locationText = "\(lat), \(long)"
        }
        addressLabel.text = locationText
    }
    
    override class func height(for message: AmityMessageModel, boundingWidth: CGFloat) -> CGFloat {
        if message.isDeleted {
            let displayNameHeight: CGFloat = message.isOwner ? 0 : 46
            return AmityMessageTableViewCell.deletedMessageCellHeight + displayNameHeight
        }
        
        var height: CGFloat = 0
        var actualWidth: CGFloat = 0
        
        // Calculate actual width based on whether the message is from the owner or not
        if message.isOwner {
            let horizontalPadding: CGFloat = 112
            actualWidth = boundingWidth - horizontalPadding
            
            let verticalPadding: CGFloat = 64
            height += verticalPadding
        } else {
            let horizontalPadding: CGFloat = 164
            actualWidth = boundingWidth - horizontalPadding
            
            let verticalPadding: CGFloat = 98
            height += verticalPadding
        }
        
        // Check if the message contains location data
        if let location = message.data?["location"] as? [String: Any], let address = location["address"] as? String, let title = location["name"] as? String {
            var text = ""
            if !title.isEmpty {
                text = title
            }
            if !address.isEmpty {
                text += "\n\(address)"
            }
            
            // Calculate the height of the expandable label
            let maximumLines = Constant.maximumLines
            let messageHeight = AmityExpandableLabel.height(for: text, font: Constant.textMessageFont, boundingWidth: actualWidth, maximumLines: maximumLines)
            height += messageHeight
        }
        
        // Add the height of the image view with aspect ratio 1:0.5
        height += actualWidth * 0.5 // Height of the image with aspect ratio 1:0.5
        height += 12 // Spacing between image and caption
        
        return height
    }
    
    private func actualWidth(for message: AmityMessageModel, boundingWidth: CGFloat) -> CGFloat {
        var actualWidth: CGFloat = 0
        
        // for cell layout and calculation, please go check this pull request https://github.com/EkoCommunications/EkoMessagingSDKUIKitIOS/pull/713
        if message.isOwner {
            let horizontalPadding: CGFloat = 112
            actualWidth = boundingWidth - horizontalPadding
        } else {
            let horizontalPadding: CGFloat = 164
            actualWidth = boundingWidth - horizontalPadding
        }
        
        return actualWidth
    }
}

private extension AmityLocationTableViewCell {
    @objc
    func imageViewTap() {
        if let location = message?.data?["location"] as? [String:Any] {
            let latitude = location["lat"] as? Double
            let longitude = location["lng"] as? Double
            let placeId = location["googlemap_place_id"] as? String

            var urlString: String
            if let latitude = latitude, let longitude = longitude {
                // Use the coordinates to open Google Maps
                if let placeId = placeId  {
                    urlString = "comgooglemaps://?q=\(latitude),\(longitude)&q=place_id:\(placeId)"
                } else {
                    urlString = "comgooglemaps://?q=\(latitude),\(longitude)"
                }
            } else {
                return
            }
            
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                // Fallback to Google Maps web if the app is not installed
                if let latitude = latitude, let longitude = longitude {
                    if let placeId = placeId {
                        urlString = "https://www.google.com/maps/search/?api=1&query=\(latitude),\(longitude)&query_place_id=\(placeId)"
                    } else {
                        urlString = "https://www.google.com/maps/search/?api=1&query=\(latitude),\(longitude)"
                    }
                } else {
                    return
                }
                
                if let url = URL(string: urlString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
    }
}
