//
//  PreviewImagePickerController.swift
//  AmityUIKit
//
//  Created by FoodStory on 26/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation
import UIKit
import Photos

class PreviewImagePickerController: AmityViewController {
    
    // MARK: - IBOutlet Properties
    @IBOutlet private weak var previweCollectionView: UICollectionView!
    
    // MARK: - Properties
    var imageList: [AmityMedia] = []
    var mediaType: AmityMediaType!
    private var screenViewModel: AmityMessageListScreenViewModelType!
    private var sendBarButtonItem: UIBarButtonItem!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpView()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.tabBar.isHidden = true
    }
    
    public static func make(media: [AmityMedia], viewModel: AmityMessageListScreenViewModelType, mediaType: AmityMediaType) -> PreviewImagePickerController {
        let vc = PreviewImagePickerController(nibName: PreviewImagePickerController.identifier, bundle: AmityUIKitManager.bundle)
        vc.imageList = media
        vc.screenViewModel = viewModel
        vc.mediaType = mediaType
        
        return vc
    }
    
    func setUpView() {
        title = "Selected images"
        sendBarButtonItem = UIBarButtonItem(title: AmityLocalizedStringSet.General.send.localizedString, style: .done, target: self, action: #selector(sendButtonTap))

        // [Improvement] Add set font style to label of save button
        sendBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.font: AmityFontSet.body,
                                                   NSAttributedString.Key.foregroundColor: AmityColorSet.primary], for: .normal)

        navigationItem.rightBarButtonItem = sendBarButtonItem

        previweCollectionView.register(UINib(nibName: PreviewImagePickerCollectionViewCell.identifier, bundle: AmityUIKitManager.bundle), forCellWithReuseIdentifier: PreviewImagePickerCollectionViewCell.identifier)
        (previweCollectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .vertical
    }

    // MARK: - Action
    
    @objc private func sendButtonTap() {
        AmityHUD.show(.loading)
        self.navigationController?.popViewController(animated: true)
        self.screenViewModel.action.send(withMedias: imageList, type: mediaType)
        AmityHUD.hide()
    }
    
    func deleteItem(at indexPath: IndexPath) {
        imageList.remove(at: indexPath.row)
        previweCollectionView.reloadData()
        
        if imageList.count == 0 {
            sendBarButtonItem.isEnabled = false
        }
    }
}

extension PreviewImagePickerController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageList.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PreviewImagePickerCollectionViewCell.identifier, for: indexPath as IndexPath) as? PreviewImagePickerCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let data = imageList[indexPath.row]
        cell.setCell(media: data)
        cell.indexPath = indexPath
        cell.deleteHandler = { [weak self] indexPath in
            self?.deleteItem(at: indexPath)
        }
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let paddingSpace = 10 * 4
        let availableWidth = collectionView.frame.width - CGFloat(paddingSpace)
        let widthPerItem = availableWidth / 3
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 3
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 5, left: 10, bottom: 3, right: 10)
    }
}
