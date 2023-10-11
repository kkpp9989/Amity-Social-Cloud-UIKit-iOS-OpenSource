//
//  AmityMessageFileTableViewCell.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 11/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import AmitySDK

class AmityMessageFileTableViewCell: AmityMessageTableViewCell {
    
    @IBOutlet weak var fileInfoView: UIStackView!
    @IBOutlet weak var fileIcon: UIImageView!
    @IBOutlet weak var fileName: UILabel!
    @IBOutlet weak var fileSize: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // Clear data
        fileIcon.image = nil
        fileName.text = nil
        fileSize.text = nil
    }

    private func setupView() {
        // Set view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(fileInfoViewTap))
        tapGesture.numberOfTouchesRequired = 1
        fileInfoView.isUserInteractionEnabled = true
        fileInfoView.addGestureRecognizer(tapGesture)
        fileInfoView.backgroundColor = .clear
        
        // Set icon
        fileIcon.image = nil
        fileIcon.contentMode = .scaleAspectFill
        
        // Set file name
        fileName.text = nil
        fileName.numberOfLines = 1
        fileName.lineBreakMode = .byTruncatingTail
        fileName.font = AmityFontSet.bodyBold
        fileName.textColor = AmityColorSet.base
        fileName.backgroundColor = .clear
        
        // Set file size
        fileSize.text = nil
        fileName.numberOfLines = 1
        fileName.lineBreakMode = .byTruncatingTail
        fileSize.font = AmityFontSet.body
        fileSize.textColor = AmityColorSet.disableTextField
        fileSize.backgroundColor = .clear
    }
    
    override func display(message: AmityMessageModel) {
        if !message.isDeleted {
            let indexPath = self.indexPath
            // Get file
            if let fileInfo = message.object.getFileInfo() {
                let file = AmityFile(state: .downloadable(fileData: fileInfo))
                if indexPath == self.indexPath {
                    // Set filename
                    fileName.text = file.fileName
                    // Set file size
                    fileSize.text = "File size: \(file.formattedFileSize())"
                    // Set Icon
                    fileIcon.image = file.fileIcon
                }
            }
        }
        super.display(message: message)
    }
}

private extension AmityMessageFileTableViewCell {
    @objc
    func fileInfoViewTap() {
        if fileIcon.image != nil {
            screenViewModel.action.performCellEvent(for: .fileDownloader(indexPath: indexPath))
        }
    }
}
