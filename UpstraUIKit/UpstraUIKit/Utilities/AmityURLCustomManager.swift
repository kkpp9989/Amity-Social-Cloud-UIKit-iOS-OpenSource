//
//  AmityURLCustomManager.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 13/9/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
// [Custom for ONE Krungthai] Custom manager, object for custom feature of URL

import UIKit
import LinkPresentation

// MARK: - AmityURLMetadata
public struct AmityURLMetadata {
    let title: String
    let domain: String
    let urlData: URL
    let imagePreview: UIImage
}

// MARK: - AmityShareExternalDomainURL
private enum AmityShareExternalDomainURL: String {
    case DEV = "https://social-one-ktb-dev.com"
    case UAT = "https://social-one-ktb-uat.com"
    case PRODUCTION = "https://social-one-ktb.com"
}

// MARK: - AmityURLCustomManager
public struct AmityURLCustomManager {
    
    // MARK: - AmityURLCustomManager | Metadata
    struct Metadata {
        static func fetchAmityURLMetadata(url: String, completion: @escaping (AmityURLMetadata?) -> Void) {
            // Create URL data by URL string
            guard let urlData = URL(string: url) else {
                completion(nil)
                return
            }

            // Get URL Metadata
            let metadataProvider = LPMetadataProvider()
            metadataProvider.startFetchingMetadata(for: urlData) { (data, error) in
                // Get result of URL Metadata
                guard let metadata = data, error == nil else {
                    completion(nil)
                    return
                }

                // Check is have title, domain and image preview for create AmityURLMetadata for send by closure
                if let title = metadata.title, let domain = urlData.host?.replacingOccurrences(of: "www.", with: ""), let imageProvider = metadata.imageProvider {
                    imageProvider.loadObject(ofClass: UIImage.self) { image, error in
                        if let previewImage = image as? UIImage {
                            completion(AmityURLMetadata(title: title, domain: domain, urlData: urlData ,imagePreview: previewImage))
                        } else {
                            completion(nil)
                        }
                    }
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    // MARK: - AmityURLCustomManager | Utilities
    struct Utilities {
        static func getURLInText(text: String) -> String? {
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
            
            // Check and get URL founded in text
            if hyperLinkTextRange.count > 0 {
                guard let firstHyperLink = hyperLinkTextRange.first?.type else { return nil } // Get first URL founded
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
    
    // MARK: - AmityURLCustomManager | ExternalURL
    struct ExternalURL {
        static func getDomainURLShareExternalURL(env: String) -> String {
            // Get domain URL by env key
            switch env {
            case "DEV":
                return AmityShareExternalDomainURL.DEV.rawValue
            case "UAT":
                return AmityShareExternalDomainURL.UAT.rawValue
            case "PRODUCTION":
                return AmityShareExternalDomainURL.PRODUCTION.rawValue
            default:
                return AmityShareExternalDomainURL.UAT.rawValue // Set UAT to default
            }
        }

        static func generateExternalURLOfPost(postId: String) -> String {
            // Get domain URL from ENV
            var domainURL = ""
            if let envKey = AmityUIKitManager.env["env_key"] as? String {
                domainURL = getDomainURLShareExternalURL(env: envKey)
            } else {
                domainURL = getDomainURLShareExternalURL(env: "") // Go to default (UAT)
            }

            // Return URL
            return "\(domainURL)/social/post/\(postId)"
        }
    }
}

// MARK: - AmityURLPreviewCacheManager
class AmityURLPreviewCacheManager {
    static let shared = AmityURLPreviewCacheManager() // Singleton instance
    
    private var urlPreviewCache: [String: AmityURLMetadata] = [:]
    private var urlCannotPreviewCache: [String] = []
    
    // Function to retrieve cached metadata
    func getCachedMetadata(forURL url: String) -> AmityURLMetadata? {
        return urlPreviewCache[url]
    }
    
    // Function to check URL is checked cannot preview
    func isCheckedURLCannotPreview(forURL url: String) -> Bool {
        return urlCannotPreviewCache.firstIndex(of: url) != nil ? true : false
    }
    
    // Function to cache metadata
    func cacheMetadata(_ metadata: AmityURLMetadata, forURL url: String) {
        urlPreviewCache[url] = metadata
    }
    
    // Function to cache URL cannot preview
    func cacheURLCannotPreview(forURL url: String) {
        urlCannotPreviewCache.append(url)
    }
}
