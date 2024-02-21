//
//  AmityURLCustomManager.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 13/9/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
// [Custom for ONE Krungthai] Custom manager, object for custom feature of URL

import UIKit
import LinkPresentation
import MobileCoreServices

// MARK: - AmityURLMetadata
public struct AmityURLMetadata {
    var title: String
    var domainURL: String
    var fullURL: String
    var urlData: URL?
    var imagePreview: UIImage?
}

// MARK: - AmityShareExternalDomainURL
private enum AmityShareExternalDomainURL: String {
    case DEV = "https://social-one-ktb-dev.com"
    case UAT = "https://social-uat.krungthai.com"
    case PRODUCTION = "https://social.krungthai.com"
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
                            completion(AmityURLMetadata(title: title, domainURL: domain, fullURL: url, urlData: urlData ,imagePreview: previewImage))
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
                
                if AmityURLCustomManager.Utilities.isURLEncoded(validUrlString) {
                    guard let url = URL(string: validUrlString) else { continue }
                    
                    hyperLinkTextRange.append(Hyperlink(range: match.range, type: .url(url: url)))
                    
//                    print("[URL] add hyperlink | url string: \(urlString) | valid url string: \(validUrlString) | url.absoluteString: \(url.absoluteString) ")
                } else {
                    guard let formattedString = validUrlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                          let url = URL(string: formattedString) else { continue }
                    
                    hyperLinkTextRange.append(Hyperlink(range: match.range, type: .url(url: url)))
                    
//                    print("[URL] add hyperlink | url string: \(urlString) | valid url string: \(validUrlString) | formattedString:\(formattedString) | url.absoluteString: \(url.absoluteString) ")
                }
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
        static func isURLEncoded(_ url: String) -> Bool {
            if let decodedString = url.removingPercentEncoding {
                return decodedString != url
            }
            return false
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

        static func generateExternalURLOfPost(post: AmityPostModel) -> String {
            // Set parameter
            var titleParameter = ""
            
            if post.targetCommunity != nil {
                titleParameter = "\(post.targetCommunity?.displayName ?? "")"
            } else {
                titleParameter = "Timeline \(post.displayName)"
            }
            
            let descriptionParameter = post.text.count > 50 ? String(post.text.prefix(50)) + "..." : post.text
            let postId = post.postId
            
            // Get domain URL from ENV
            var domainURL = ""
            if let envKey = AmityUIKitManager.env["env_key"] as? String {
                domainURL = getDomainURLShareExternalURL(env: envKey)
            } else {
                domainURL = getDomainURLShareExternalURL(env: "") // Go to default (UAT)
            }
            
            // Encode URL and return URL
            let originalURL = "\(domainURL)/?title=\(titleParameter)&desc=\(descriptionParameter)&postId=\(postId)"
//            print("[URL] original: \(originalURL)")
            if let encodeURL = originalURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
//                print("[URL] encode: \(encodeURL)")
                return encodeURL
            } else {
                return originalURL
            }
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
    
    func removeCacheMetadata(forURL url: String) {
        urlPreviewCache.removeValue(forKey: url)
    }
    
    // Function to cache URL cannot preview
    func cacheURLCannotPreview(forURL url: String) {
        urlCannotPreviewCache.append(url)
    }
}
