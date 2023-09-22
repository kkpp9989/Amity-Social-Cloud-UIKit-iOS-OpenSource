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
            
            /* [Custom for ONE Krungthai][URL Preview] Add check URL in text for show URL preview or not */
            if let urlString = AmityURLCustomManager.getURLInText(text: post.text) { // Case : Have URL in text
                if let cachedMetadata = AmityURLPreviewCacheManager.shared.getCachedMetadata(forURL: urlString) { // Case : This url have current data -> Use cached for set display URL preview
                    // Display URL Preview from cache URL metadata
                    cell.displayURLPreview(metadata: cachedMetadata)
                    // Reload row if row is visible
                    if let indexPathOfCell = cell.indexPath, let _ = tableView.indexPathsForVisibleRows?.contains(where: { _ in indexPath == indexPathOfCell }) {
                        tableView.reloadRows(at: [indexPathOfCell], with: .automatic)
                    }
                } else { // Case : This url don't have current data -> Get new URL metadata for set display URL preview
                    // Get new URL metadata
                    AmityURLCustomManager.fetchAmityURLMetadata(url: urlString) { metadata in
                        DispatchQueue.main.async {
                            if let urlMetadata: AmityURLMetadata = metadata { // Case : Can get new URL metadata -> set display URL preview
                                // Save new URL metadata to cache
                                AmityURLPreviewCacheManager.shared.cacheMetadata(urlMetadata, forURL: urlString)
                                // Display URL Preview from new URL metadata
                                cell.displayURLPreview(metadata: urlMetadata)
                                // Reload row if row is visible
                                if let indexPathOfCell = cell.indexPath, let _ = tableView.indexPathsForVisibleRows?.contains(where: { _ in indexPath == indexPathOfCell }) {
                                    tableView.reloadRows(at: [indexPathOfCell], with: .automatic)
                                }
                            } else { // Case : Can get new URL metadata -> hide URL preview
                                // Hide URL Preview
                                cell.hideURLPreview()
                            }
                        }
                    }
                }
            } else { // Case : Don't have URL in text
                // Hide URL Preview
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
            cell.display(post: post, comment: comment, indexPath: indexPath) { isHaveURLPreview, indexPathOfCell in
                // Reload row if row is visible (reload all preview cell because some cell show URL preview same other cell even though don't have URL in text)
                if let _ = tableView.indexPathsForVisibleRows?.contains(where: { _ in indexPath == indexPathOfCell }) {
                    tableView.reloadRows(at: [indexPathOfCell], with: .automatic)
                }
            }
            return cell
        }
    }
    
    public func getComponentHeight(indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

