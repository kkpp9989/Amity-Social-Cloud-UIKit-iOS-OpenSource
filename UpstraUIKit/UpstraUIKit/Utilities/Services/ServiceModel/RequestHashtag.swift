//
//  RequestHashtag.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 19/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation

struct RequestHashtag {
    
    let requestMeta = BaseRequestMeta()
    let currentUserToken = AmityUIKitManager.currentUserToken
    var keyword: String = ""
    var size: Int = 3

    func request(_ completion: @escaping(Result<HashtagModel,Error>) -> ()) {
        var domainURL = "https://beta.amity.services"
//        if let envKey = AmityUIKitManager.env["env_key"] as? String {
//            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: envKey)
//        } else {
//            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: "") // Go to default (UAT)
//        }
        requestMeta.urlRequest = "\(domainURL)/search/hashtag"
        requestMeta.header = [["Content-Type": "application/json",
                               "Accept": "application/json",
                               "Authorization": "Bearer \(currentUserToken)"]]
        requestMeta.method = .post
        requestMeta.encoding = .jsonEncoding
        requestMeta.params = ["query": ["text": keyword], "sort": [["count": "asc"], ["createdAt": "desc"]], "from": 0, "size": size]
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure("Not data" as! Error))
                return
            }
            switch httpResponse.statusCode {
            case 200:
                guard let dataModel = try? JSONDecoder().decode(HashtagModel.self, from: data) else {
                    completion(.failure("Json Decode Error" as! Error))
                    return
                }
                completion(.success(dataModel))
            case 400...499:
                completion(.failure("Page not found" as! Error))
            default:
                completion(.failure("Service Error" as! Error))
            }
        }
        
    }
    
}
