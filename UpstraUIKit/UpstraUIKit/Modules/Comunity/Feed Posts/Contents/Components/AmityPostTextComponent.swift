//
//  AmityPostTextComponent.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/11/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit
/**
 This is a default component for providing to display a `Text` post
 
 # Consists of 4 cells
 - `AmityPostHeaderTableViewCell`
 - `AmityPostTextTableViewCell`
 - `AmityPostFooterTableViewCell`
 - `AmityPostPreviewCommentTableViewCell`
 */
public struct AmityPostTextComponent: AmityPostComposable {
    
    private(set) public var post: AmityPostModel
    
    public init(post: AmityPostModel) {
        self.post = post
    }
    
    public func getComponentCount(for index: Int) -> Int {
        switch post.appearance.displayType {
        case .feed:
            return AmityPostConstant.defaultNumberComponent + post.maximumLastestComments + post.viewAllCommentSection
        case .postDetail:
            return AmityPostConstant.defaultNumberComponent
        }
    }
    
    public func getComponentCell(_ tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.row {
        case 0:
            let cell: AmityPostHeaderTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.display(post: post)
            return cell
        case 1:
            let cell: AmityPostTextTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.display(post: post, indexPath: indexPath)

//            print("[Post][Get] text: \(post.text) | post metadata: \(post.metadata)")
            /* [Custom for ONE Krungthai][URL Preview] Add check URL in text for show URL preview or not */
            if let title = post.metadata?["url_preview_cache_title"] as? String, title != "",
               let fullURLString = post.metadata?["url_preview_cache_url"] as? String, fullURLString != "",
               let isShowURLPreview = post.metadata?["is_show_url_preview"] as? Bool, isShowURLPreview,
               let urlData = URL(string: fullURLString), let domainURL = urlData.host?.replacingOccurrences(of: "www.", with: ""),
               let urlInText = AmityURLCustomManager.Utilities.getURLInText(text: post.text), urlInText == fullURLString { // Case : Display URL preview
                
                if let cachedMetadata = AmityURLPreviewCacheManager.shared.getCachedMetadata(forURL: fullURLString) { // Case: [Display URL preview] Have URL metadata in local cache -> Display URL preview
                    cell.displayURLPreview(metadata: cachedMetadata, isLoadingImagePreview: false)
                } else { // Case: [Display URL preview] Don't Have URL metadata in local cache -> Set new url metadata cache in local from post metadata and display URL preview and waiting load image preview
                    // Display URL Preview (without image preview)
                    let urlMetadata = AmityURLMetadata(title: title, domainURL: domainURL, fullURL: fullURLString, urlData: urlData, imagePreview: nil)
                    cell.displayURLPreview(metadata: urlMetadata, isLoadingImagePreview: true)
                    
                    // Get URL metadata fot image preview
                    AmityURLCustomManager.Metadata.fetchAmityURLMetadata(url: fullURLString) { [self] metadata in
                        DispatchQueue.main.async {
                            // Update image preview to current URL metadata cache
                            var currentURLMetadata: AmityURLMetadata
                            if let newURLMetadata: AmityURLMetadata = metadata {
                                currentURLMetadata = AmityURLMetadata(title: title, domainURL: domainURL, fullURL: fullURLString, urlData: urlData, imagePreview: newURLMetadata.imagePreview)
                            } else {
                                currentURLMetadata = AmityURLMetadata(title: title, domainURL: domainURL, fullURL: fullURLString, urlData: urlData)
                            }
                            AmityURLPreviewCacheManager.shared.cacheMetadata(currentURLMetadata, forURL: fullURLString)
                            
                            // Display URL Preview (with image preview)
                            cell.displayURLPreview(metadata: currentURLMetadata, isLoadingImagePreview: false)
                        }
                    }
                }
            } else { // Case : Hide URL preview
                cell.hideURLPreview()
            }
            
            return cell
        case 2:
            let cell: AmityPostFooterTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            cell.display(post: post)
            return cell
        case AmityPostConstant.defaultNumberComponent + post.maximumLastestComments:
            let cell: AmityPostViewAllCommentsTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            return cell
        default:
            let cell: AmityPostPreviewCommentTableViewCell = tableView.dequeueReusableCell(for: indexPath)
            let comment = post.getComment(at: indexPath, totalComponent: AmityPostConstant.defaultNumberComponent)
            let isExpanded = post.commentExpandedIds.contains(comment?.id ?? "absolutely-cannot-found-xc")
            cell.setIsExpanded(isExpanded)
            cell.display(post: post, comment: comment, indexPath: indexPath)
            return cell
        }
    }
    
    public func getComponentHeight(indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

