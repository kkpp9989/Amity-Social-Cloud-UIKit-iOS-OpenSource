//
//  PreviewImagePickerCollectionViewCell.swift
//  AmityUIKit
//
//  Created by FoodStory on 28/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit
import Photos

final class PreviewImagePickerCollectionViewCell: UICollectionViewCell {
    
    // MARK: - IBOutlet Properties
    @IBOutlet private var coverImageView: UIImageView!
    @IBOutlet private var deleteButton: UIButton!
    @IBOutlet private var durationView: UIStackView!
    @IBOutlet private var durationLabel: UILabel!
    
    @IBOutlet private var alertView: UIView!
    @IBOutlet private var alertLabel: UILabel!
    @IBOutlet private var alertImageView: UIImageView!

    // MARK: - Properties
    var indexPath: IndexPath?
    private let durationFormatter = DateComponentsFormatter()
    
    // MARK: - Callback handler
    var deleteHandler: ((IndexPath) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        deleteButton.addTarget(self, action: #selector(deleteTap(_:)), for: .touchUpInside)
        
        // Duration View
        durationView.isHidden = true
        durationView.backgroundColor = UIColor(hex: "000000", alpha: 0.7)
        durationView.clipsToBounds = true
        durationView.layer.cornerRadius = 4
        durationLabel.font = AmityFontSet.caption
        durationLabel.textColor = AmityThemeManager.currentTheme.baseInverse
        
        alertView.isHidden = true
        alertView.backgroundColor = .black.withAlphaComponent(0.4)
        alertLabel.font = AmityFontSet.bodyBold
        alertLabel.textColor = .white
        alertLabel.text = "Too large"
        alertImageView.image = AmityIconSet.iconAlertInfoWhite
    }
    
    func setCell(media: AmityMedia) {
        switch media.state {
        case .image(let image):
            coverImageView.image = image
        case .downloadableImage: break
        case .downloadableVideo: break
        case .localAsset(let asset):
            coverImageView.image = getAssetThumbnail(asset: asset)
            if asset.mediaType == .video {
                durationView.isHidden = false
                durationLabel.text = getDurationFormatter(showHour: asset.duration >= 3600).string(from: asset.duration)
            } else {
                durationLabel.isHidden = true
            }
            
            checkFileSize(for: asset) { isShouldHidden in
                DispatchQueue.main.async {
                    self.alertView.isHidden = !isShouldHidden
                }
            }
        case .localURL, .uploadedImage, .uploadedVideo, .none: break
        case .uploading, .error:break
        }
    }
    
    private func getDurationFormatter(showHour: Bool) -> DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = showHour ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }
    
    func getAssetThumbnail(asset: PHAsset) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var thumbnail = UIImage()
        
        // Request the original dimensions of the asset
        let targetSize = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
        
        option.isSynchronous = true
        option.deliveryMode = .opportunistic
        
        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            thumbnail = result!
        })
        
        return thumbnail
    }

    func checkFileSize(for asset: PHAsset, completion: @escaping (Bool) -> Void) {
        PHImageManager.default().requestAVAsset(forVideo: asset, options: nil) { (avAsset, _, _) in
            guard let avAsset = avAsset as? AVURLAsset else {
                completion(false)
                return
            }
            
            do {
                let fileURL = avAsset.url
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                if let fileSize = fileAttributes[.size] as? Double {
                    let fileSizeInMB = fileSize / (1024 * 1024)
                    let isFileSizeGreaterThan300MB = fileSizeInMB > 300.0
                    completion(isFileSizeGreaterThan300MB)
                } else {
                    completion(false)
                }
            } catch {
                completion(false)
            }
        }
    }
}

private extension PreviewImagePickerCollectionViewCell {
    
    @objc func deleteTap(_ sender: UIButton) {
        guard let indexPath = indexPath else { return }
        deleteHandler?(indexPath)
    }
}
