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
    @IBOutlet private weak var sendButton: UIButton!
    @IBOutlet private weak var navigationTitleLabel: UILabel!
    
    // MARK: - Properties
    var imageList: [AmityMedia] = []
    var mediaType: AmityMediaType!
    var navigationTitle: String = ""
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
    
    public static func make(media: [AmityMedia],
                          viewModel: AmityMessageListScreenViewModelType,
                          mediaType: AmityMediaType,
                          title: String) -> PreviewImagePickerController {
        let vc = PreviewImagePickerController(nibName: PreviewImagePickerController.identifier, bundle: AmityUIKitManager.bundle)
        vc.imageList = media
        vc.screenViewModel = viewModel
        vc.mediaType = mediaType
        vc.navigationTitle = title
        
        return vc
    }
    
    func setUpView() {
        sendButton.setTitle(AmityLocalizedStringSet.General.send.localizedString, for: .normal)
        sendButton.titleLabel?.font = AmityFontSet.body
        
        navigationTitleLabel.text = navigationTitle
        navigationTitleLabel.font = AmityFontSet.title
        navigationTitleLabel.adjustsFontSizeToFitWidth = true
        
        previweCollectionView.register(UINib(nibName: PreviewImagePickerCollectionViewCell.identifier, bundle: AmityUIKitManager.bundle), forCellWithReuseIdentifier: PreviewImagePickerCollectionViewCell.identifier)
        (previweCollectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.scrollDirection = .vertical
    }
    
    // MARK: - Action
    
    @IBAction func sendButtonTap(_ sender: UIButton) {
        AmityHUD.show(.loading)
        self.screenViewModel.action.send(withMedias: imageList, type: mediaType)
        
        var presentingViewController = self.presentingViewController
        while presentingViewController != nil {
            let dismissedVC = presentingViewController
            presentingViewController = presentingViewController?.presentingViewController
            dismissedVC?.dismiss(animated: false, completion: nil)
        }
        
        AmityHUD.hide()
    }
    
    @IBAction func backButtonTap(_ sender: UIButton) {
        self.dismiss(animated: false)
    }
    
    func deleteItem(at indexPath: IndexPath) {
        imageList.remove(at: indexPath.row)
        previweCollectionView.reloadData()
        
        if imageList.count == 0 {
            sendButton.isEnabled = false
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
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 3
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 0, left: 10, bottom: 3, right: 15)
    }
}