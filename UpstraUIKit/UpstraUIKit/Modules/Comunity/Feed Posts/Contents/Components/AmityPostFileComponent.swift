//
//  AmityPostFileComponent.swift
//  AmityUIKit
//
//  Created by sarawoot khunsri on 2/11/21.
//  Copyright © 2021 Amity. All rights reserved.
//

import UIKit

/**
 This is a default component for providing to display a `File` post
 
 # Consists of 4 cells
 - `AmityPostHeaderTableViewCell`
 - `AmityPostFileTableViewCell`
 - `AmityPostFooterTableViewCell`
 - `AmityPostPreviewCommentTableViewCell`
 
 */
public struct AmityPostFileComponent: AmityPostComposable {

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
            let cell: AmityPostFileTableViewCell = tableView.dequeueReusableCell(for: indexPath)
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
    
    public func disableTopPadding(cell: AmityPostHeaderProtocol) {
        cell.disableTopPadding()
    }
    
    public func getComponentHeight(indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    
}
