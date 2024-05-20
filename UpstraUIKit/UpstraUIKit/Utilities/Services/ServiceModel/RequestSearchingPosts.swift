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
    var size: Int = 20

    func request(_ completion: @escaping(Result<AmitySearchPostsModel,Error>) -> ()) {
        let domainURL = "https://beta.amity.services"
        requestMeta.urlRequest = "\(domainURL)/search/v2/posts"
        requestMeta.header = [["Content-Type": "application/json",
                               "Accept": "application/json",
                               "Authorization": "Bearer \(currentUserToken)"]]
        requestMeta.method = .post
        requestMeta.encoding = .jsonEncoding
        requestMeta.params = ["query": ["hashtagList": keyword, "targetType": "all"], "from": from, "size": size, "userId": userId, "apiKey": apiKey]
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            switch httpResponse.statusCode {
            case 200:
                guard let dataResponse = try? JSONDecoder().decode(AmitySearchPostsModel.self, from: data) else {
                    completion(.failure(HandleError.JsonDecodeError))
                    return
                }
                completion(.success(dataResponse))
            case 400...499:
                completion(.failure(HandleError.notFound))
            default:
                completion(.failure(HandleError.connectionError))
            }
        }
        
    }
    
    func requestPost(_ completion: @escaping(Result<AmitySearchPostsModel,Error>) -> ()) {
        let domainURL = "https://beta.amity.services"
        requestMeta.urlRequest = "\(domainURL)/search/v2/posts"
        requestMeta.header = [["Content-Type": "application/json",
                               "Accept": "application/json",
                               "Authorization": "Bearer \(currentUserToken)"]]
        requestMeta.method = .post
        requestMeta.encoding = .jsonEncoding
        requestMeta.params = ["query": ["text": keyword, "targetType": "public", "publicSearch": true], "from": from, "size": size, "userId": userId, "apiKey": apiKey]
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            switch httpResponse.statusCode {
            case 200:
                guard let dataResponse = try? JSONDecoder().decode(AmitySearchPostsModel.self, from: data) else {
                    completion(.failure(HandleError.JsonDecodeError))
                    return
                }
                completion(.success(dataResponse))
            case 400...499:
                completion(.failure(HandleError.notFound))
            default:
                completion(.failure(HandleError.connectionError))
            }
        }
        
    }
}
