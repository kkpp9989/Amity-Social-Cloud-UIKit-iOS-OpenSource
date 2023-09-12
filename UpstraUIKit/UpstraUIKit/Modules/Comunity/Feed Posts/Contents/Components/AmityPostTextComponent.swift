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
            cell.display(post: post, comment: comment)
            return cell
        }
    }
    
    public func getComponentHeight(indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    private func getURLInText(text: String) -> String? {
        // Detect URLs
        let urlDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let urlMatches = urlDetector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        var hyperLinkTextRange: [Hyperlink] = []
        
        for match in urlMatches {
            guard let textRange = Range(match.range, in: text) else { continue }
            let urlString = String(text[textRange])
            let validUrlString = urlString.hasPrefixIgnoringCase("http") ? urlString : "http://\(urlString)"
            guard let formattedString = validUrlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: formattedString) else { continue }
            hyperLinkTextRange.append(Hyperlink(range: match.range, type: .url(url: url)))
        }
        
        if hyperLinkTextRange.count > 0 {
            guard let firstHyperLink = hyperLinkTextRange.first?.type else { return nil }
            switch firstHyperLink {
            case .url(let url):
                return url.absoluteString
            default:
                return nil
            }
        } else {
            return nil
        }
    }
}
