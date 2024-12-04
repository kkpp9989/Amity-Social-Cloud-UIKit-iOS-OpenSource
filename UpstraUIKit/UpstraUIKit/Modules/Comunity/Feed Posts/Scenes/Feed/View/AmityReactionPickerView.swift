//
//  AmityReactionPickerView.swift
//  AmityUIKit
//
//  Created by Teeraphan on 13/7/23.
//

import UIKit

public class AmityReactionPickerView: UIView {

    private var contentView: UIView!
    private var collectionView: UICollectionView!
    
    private let lineSpacing: CGFloat = 0.0
    private let verticalSpacing: CGFloat = 12.0
    private let horizontalSpacing: CGFloat = 8.0
    
    private let reactionTypes: [AmityReactionType] = [.create, .honest, .harmony, .success, .society, .like, .love]
    
    public var viewWidth: CGFloat {
        
        let maxWidth = UIScreen.main.bounds.size.width - 16 - 16
        let contentWidth = (48*7) + (horizontalSpacing * 2)
        return min(maxWidth, contentWidth)
    }
    
    public let viewHeight: CGFloat = 84
    
    public var onSelect:((AmityReactionType) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        
        contentView = UIView(frame: .zero)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(contentView)
        
        setupView()
    }
    
    private func setupView() {
        
        self.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        
        self.contentView.backgroundColor = UIColor.white
        
        self.layer.shadowColor = UIColor.lightGray.cgColor
        self.layer.shadowOpacity = 0.5
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowRadius = 12
        self.layer.masksToBounds = false
        
        self.contentView.layer.cornerRadius = 20
        self.contentView.layer.masksToBounds = true
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 48, height: 60)
        layout.minimumLineSpacing = lineSpacing
        layout.sectionInset = UIEdgeInsets(top: 0, left: horizontalSpacing, bottom: 0, right: horizontalSpacing)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.white
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(AmityReactionPickerCollectionViewCell.self)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        self.contentView.addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        collectionView.reloadData()
    }
}

extension AmityReactionPickerView: UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let onSelect = onSelect {
            onSelect(reactionTypes[indexPath.item])
        }
    }
}

extension AmityReactionPickerView: UICollectionViewDataSource {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return reactionTypes.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell: AmityReactionPickerCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.display(reactionTypes[indexPath.item])
        return cell
    }
}
