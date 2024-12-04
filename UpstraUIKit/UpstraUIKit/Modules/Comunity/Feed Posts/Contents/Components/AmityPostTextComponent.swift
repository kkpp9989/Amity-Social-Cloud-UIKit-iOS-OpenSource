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
    
    private var postHasPreviewLink: Bool {
        if let isShowURLPreview = post.metadata?["is_show_url_preview"] as? Bool {
            return isShowURLPreview
        } else {
            return false
        }
    }
    
    public init(post: AmityPostModel) {
        self.post = post
    }
    
    public func getComponentCount(for index: Int) -> Int {
        switch post.appearance.displayType {
        case .feed:
            return AmityPostConstant.defaultNumberComponent + post.maximumLastestComments + post.viewAllCommentSection + (postHasPreviewLink ? 1 : 0)
        case .postDetail:
            return AmityPostConstant.defaultNumberComponent + (postHasPreviewLink ? 1 : 0)
        }
    }
    
    public func getComponentCell(_ tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        if postHasPreviewLink {
            switch indexPath.row {
            case 0:
                let cell: AmityPostHeaderTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.display(post: post)
                return cell
                
            case 1:
                let cell: AmityPostTextTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.display(post: post, indexPath: indexPath)
                return cell
                
            case 2:
                let cell: AmityPreviewLinkCell = tableView.dequeueReusableCell(for: indexPath)
                cell.display(post: post)
                return cell
                
                
            case 3:
                let cell: AmityPostFooterTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.display(post: post)
                return cell
                
            case 4,5:
                let comment = post.getComment(at: indexPath, totalComponent: AmityPostConstant.defaultNumberComponent + 1) // plus 1 as it has preview link component
                if let isShowURLPreview = comment?.metadata?["is_show_url_preview"] as? Bool, isShowURLPreview {
                    let cell: AmityPostPreviewCommentWithURLPreviewTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                    let isExpanded = post.commentExpandedIds.contains(comment?.id ?? "absolutely-cannot-found-xc")
                    cell.setIsExpanded(isExpanded)
                    cell.display(post: post, comment: comment, indexPath: indexPath)
                    return cell
                } else {
                    let cell: AmityPostPreviewCommentTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                    let isExpanded = post.commentExpandedIds.contains(comment?.id ?? "absolutely-cannot-found-xc")
                    cell.setIsExpanded(isExpanded)
                    cell.display(post: post, comment: comment, indexPath: indexPath)
                    return cell
                }
            default:
                let cell: AmityPostViewAllCommentsTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                return cell
            }
        } else {
            switch indexPath.row {
            case 0:
                let cell: AmityPostHeaderTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.display(post: post)
                return cell
                
            case 1:
                let cell: AmityPostTextTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.display(post: post, indexPath: indexPath)
                return cell
                
            case 2:
                let cell: AmityPostFooterTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.display(post: post)
                return cell
                
            case AmityPostConstant.defaultNumberComponent + post.maximumLastestComments:
                let cell: AmityPostViewAllCommentsTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                return cell
                
            default:
                let comment = post.getComment(at: indexPath, totalComponent: AmityPostConstant.defaultNumberComponent)
                if let isShowURLPreview = comment?.metadata?["is_show_url_preview"] as? Bool, isShowURLPreview {
                    let cell: AmityPostPreviewCommentWithURLPreviewTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                    let isExpanded = post.commentExpandedIds.contains(comment?.id ?? "absolutely-cannot-found-xc")
                    cell.setIsExpanded(isExpanded)
                    cell.display(post: post, comment: comment, indexPath: indexPath)
                    return cell
                } else {
                    let cell: AmityPostPreviewCommentTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                    let isExpanded = post.commentExpandedIds.contains(comment?.id ?? "absolutely-cannot-found-xc")
                    cell.setIsExpanded(isExpanded)
                    cell.display(post: post, comment: comment, indexPath: indexPath)
                    return cell
                }
            }
        }
    }
    
    public func disableTopPadding(cell: AmityPostHeaderProtocol) {
        cell.disableTopPadding()
    }
    
    public func getComponentHeight(indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}

