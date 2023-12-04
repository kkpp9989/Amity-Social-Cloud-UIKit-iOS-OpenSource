//
//  AmityEditMenuViewController.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 30/11/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

class AmityEditMenuViewController: UIViewController {
    
    // MARK: - Component
    @IBOutlet private weak var menuListView: UICollectionView!
    public var currentDynamicTableViewWidth: CGFloat { return self.maxRowContentWidth }
    public var currentDynamicTableViewHeight: CGFloat { return Constant.spacing + Constant.cellHeightSize + Constant.spacing }
    private(set) var maxRowContentWidth: CGFloat = 4
    
    // MARK: - Properties
    var items: [AmityEditMenuItem] = []
    var selectedText: String?
    
    struct Constant {
        static let cellWidthSize: CGFloat = 56
        static let cellHeightSize: CGFloat = 56
        static let spacing: CGFloat = 4
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    static func make() -> AmityEditMenuViewController {
        return AmityEditMenuViewController(nibName: AmityEditMenuViewController.identifier, bundle: AmityUIKitManager.bundle)
    }
    
    private func setupView() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 4
        flowLayout.itemSize = CGSize(width: Constant.cellWidthSize, height: Constant.cellHeightSize)
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: Constant.spacing, bottom: 0, right: Constant.spacing)
        menuListView.collectionViewLayout = flowLayout
        menuListView.register(AmityEditMenuCollectionViewCell.nib, forCellWithReuseIdentifier: AmityEditMenuCollectionViewCell.identifier)
        menuListView.backgroundColor = UIColor(hex: "292B32")
        view.backgroundColor = UIColor(hex: "292B32")
        menuListView.isScrollEnabled = false
        menuListView.showsHorizontalScrollIndicator = false
        menuListView.dataSource = self
        menuListView.delegate = self
        
        /** Trigger table view to reload data **/
        menuListView.reloadData()
        menuListView.layoutIfNeeded()
        
    }
    
    func configure(items: [AmityEditMenuItem], selectedText: String?) {
        /** Set items of pull down menu **/
        self.items = items
        self.selectedText = selectedText
    }
    
}

extension AmityEditMenuViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        /** Dismiss view controller & overlay view **/
        dismiss(animated: true)
        NotificationCenter.default.post(name: Notification.Name.View.didDismiss, object: nil)
        
        /** Run handler action of button **/
        let item = items[indexPath.row]
        item.completion?()
    }
}

extension AmityEditMenuViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AmityEditMenuCollectionViewCell.identifier, for: indexPath) as? AmityEditMenuCollectionViewCell else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: AmityEditMenuCollectionViewCell.identifier, for: indexPath)
        }
        
        cell.display(with: items[indexPath.row])
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        maxRowContentWidth += Constant.cellHeightSize + Constant.spacing
    }
}
