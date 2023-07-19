//
//  RequestSearchingPosts.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 19/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation

struct RequestSearchingPosts {
    
    let requestMeta = BaseRequestMeta()
    let currentUserToken = AmityUIKitManagerInternal.shared.currentUserToken
    let userId = AmityUIKitManagerInternal.shared.currentUserId
    let apiKey = AmityUIKitManagerInternal.shared.apiKey
    var keyword: String = ""
    var from: Int = 0

    func request(_ completion: @escaping(Result<AmitySearchPostsModel,Error>) -> ()) {
        var domainURL = "https://beta.amity.services"
//        if let envKey = AmityUIKitManager.env["env_key"] as? String {
//            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: envKey)
//        } else {
//            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: "") // Go to default (UAT)
//        }
        requestMeta.urlRequest = "\(domainURL)/search/v2/posts"
        requestMeta.header = [["Content-Type": "application/json",
                               "Accept": "application/json",
                               "Authorization": "Bearer \(currentUserToken)"]]
        requestMeta.method = .post
        requestMeta.encoding = .jsonEncoding
        requestMeta.params = ["query": ["hashtagList": keyword, "targetType": "public", "publicSearch": true], "from": from, "size": 20, "userId": userId, "apiKey": apiKey]
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure("Not data" as! Error))
                return
            }
            switch httpResponse.statusCode {
            case 200:
                guard let dataResponse = try? JSONDecoder().decode(AmitySearchPostsModel.self, from: data) else {
                    completion(.failure("Json Decode Error" as! Error))
                    return
                }
                completion(.success(dataResponse))
            case 400...499:
                completion(.failure("Page not found" as! Error))
            default:
                completion(.failure("Service Error" as! Error))
            }
        }
        
    }
    
}
