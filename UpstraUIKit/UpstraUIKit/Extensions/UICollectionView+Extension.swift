//
//  UICollectionView+Extension.swift
//  UpstraUIKit
//
//  Created by Nontapat Siengsanor on 28/10/2563 BE.
//  Copyright © 2563 Upstra. All rights reserved.
//

import UIKit

extension UICollectionView {
    
    func dequeueReusableCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T {
        return dequeueReusableCell(withReuseIdentifier: T.identifier, for: indexPath) as! T
    }
    
}
