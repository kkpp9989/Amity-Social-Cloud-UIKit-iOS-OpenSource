//
//  AmityPreviewLinkWizard.swift
//  AmityUIKit
//
//  Created by Zay Yar Htun on 10/17/23.
//  Copyright © 2023 Amity. All rights reserved.
//

import Foundation
import LinkPresentation

struct LPLinkMetadataCache {
    var metadata: LPLinkMetadata?
    var timestamp: Date
}

class AmityPreviewLinkWizard {
    
    static let shared = AmityPreviewLinkWizard()
    
    var metadataCache: [String: LPLinkMetadataCache] = [:]
    
    private init() {}
    
    func detectLinks(input: String) -> [URL] {
        var links: [URL] = []
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = detector.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))

            for match in matches {
                guard let range = Range(match.range, in: input),
                      let url = URL(string: {
                          let rawStr = String(input[range])
                          if rawStr.hasPrefix("http") {
                              return rawStr
                          } else {
                              return "https://" + rawStr
                          }
                      }()) else { continue }
            
                links.append(url)
            }
        } catch {}
        
        return links
    }
    
    func detectURLStringWithURLEncoding(text: String) -> String? {
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
    
    @MainActor
    func getMetadata(url: URL) async -> LPLinkMetadata? {
        if let cache = metadataCache[url.absoluteString], Date().timeIntervalSince(cache.timestamp) < 86400 {
            return cache.metadata
        }
        
        let metadataProvider = LPMetadataProvider()
        do {
            let metadata = try await metadataProvider.startFetchingMetadata(for: url)
            metadataCache[url.absoluteString] = LPLinkMetadataCache(metadata: metadata, timestamp: Date())
        } catch {
            metadataCache[url.absoluteString] = LPLinkMetadataCache(metadata: nil, timestamp: Date())
        }
        
        return metadataCache[url.absoluteString]?.metadata
    }
}
