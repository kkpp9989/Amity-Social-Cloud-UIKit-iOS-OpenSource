// The MIT License (MIT)
//
// Copyright (c) 2015 Joakim Gyllström
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit
import Photos

class NewAssetsCollectionViewDataSource : NSObject, UICollectionViewDataSource {
    private static let assetCellIdentifier = "AssetCell"
    private static let videoCellIdentifier = "VideoCell"
    
    var settings: NewSettings!
    var fetchResult: PHFetchResult<PHAsset> {
        didSet {
            imageManager.stopCachingImagesForAllAssets()
        }
    }
    var imageSize: CGSize = .zero {
        didSet {
            imageManager.stopCachingImagesForAllAssets()
        }
    }

    private let imageManager = PHCachingImageManager()
    private let durationFormatter = DateComponentsFormatter()
    private let store: NewAssetStore
    private let contentMode: PHImageContentMode = .aspectFill
    
    init(fetchResult: PHFetchResult<PHAsset>, store: NewAssetStore) {
        self.fetchResult = fetchResult
        self.store = store
        durationFormatter.unitsStyle = .positional
        durationFormatter.zeroFormattingBehavior = [.pad]
        durationFormatter.allowedUnits = [.minute, .second]
        super.init()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let asset = fetchResult[indexPath.row]
        let animationsWasEnabled = UIView.areAnimationsEnabled
        let cell: NewAssetCollectionViewCell
        
        UIView.setAnimationsEnabled(false)
        if asset.mediaType == .video {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewAssetsCollectionViewDataSource.videoCellIdentifier, for: indexPath) as! NewVideoCollectionViewCell
            let videoCell = cell as! NewVideoCollectionViewCell
            videoCell.durationLabel.text = durationFormatter.string(from: asset.duration)
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: NewAssetsCollectionViewDataSource.assetCellIdentifier, for: indexPath) as! NewAssetCollectionViewCell
        }
        UIView.setAnimationsEnabled(animationsWasEnabled)

        cell.accessibilityIdentifier = "Photo \(indexPath.item + 1)"
        cell.accessibilityTraits = UIAccessibilityTraits.button
        cell.isAccessibilityElement = true
        cell.settings = settings
        
        loadImage(for: asset, in: cell)
        
        cell.selectionIndex = store.index(of: asset)
        
        return cell
    }
    
    static func registerCellIdentifiersForCollectionView(_ collectionView: UICollectionView?) {
        collectionView?.register(NewAssetCollectionViewCell.self, forCellWithReuseIdentifier: assetCellIdentifier)
        collectionView?.register(NewVideoCollectionViewCell.self, forCellWithReuseIdentifier: videoCellIdentifier)
    }
    
    private func loadImage(for asset: PHAsset, in cell: NewAssetCollectionViewCell) {
        // Cancel any pending image requests
        if cell.tag != 0 {
            imageManager.cancelImageRequest(PHImageRequestID(cell.tag))
        }
        
        // Request image
        cell.tag = Int(imageManager.requestImage(for: asset, targetSize: imageSize, contentMode: contentMode, options: settings.fetch.preview.photoOptions) { (image, _) in
            guard let image = image else { return }
            cell.imageView.image = image
        })
    }
}

extension NewAssetsCollectionViewDataSource: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let assets = indexPaths.map { fetchResult[$0.row] }
        imageManager.startCachingImages(for: assets, targetSize: imageSize, contentMode: contentMode, options: nil)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
    }
}
