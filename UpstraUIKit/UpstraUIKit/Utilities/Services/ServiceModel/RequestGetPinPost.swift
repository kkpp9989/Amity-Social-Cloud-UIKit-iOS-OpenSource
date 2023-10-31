//
//  RequestGetPinPost.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 21/9/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation

struct RequestGetPinPost {
    
    let requestMeta = BaseRequestMeta()
    let currentUserToken = AmityUIKitManager.currentUserToken
    
    func requestGetPinPost(_ type: AmityPostFeedType,_ completion: @escaping(Result<AmityPinPostModel,Error>) -> ()) {
        var domainURL = ""
        if let envKey = AmityUIKitManager.env["env_key"] as? String {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: envKey)
        } else {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: "") // Go to default (UAT)
        }
        
        var endpointUrl: String = ""
        switch type {
        case .globalFeed:
            endpointUrl = "\(domainURL)/pin-post?targetType=global"
        case .communityFeed(let communityId):
            endpointUrl = "\(domainURL)/pin-post?targetType=community&targetId=\(communityId)"
        default:
            endpointUrl = "\(domainURL)/pin-post"
        }
                
        requestMeta.urlRequest = endpointUrl
        requestMeta.header = [["Authorization": "Bearer \(currentUserToken)"]]
        requestMeta.method = .get
        requestMeta.encoding = .urlEncoding
        
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            
            // Print the JSON response
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []),
               let jsonData = try? JSONSerialization.data(withJSONObject: jsonResponse, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("-------> JSON Response: \(jsonString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let dataModel = try? JSONDecoder().decode(AmityPinPostModel.self, from: data) else {
                    completion(.failure(HandleError.JsonDecodeError))
                    return
                }
                completion(.success(dataModel))
            case 400...499:
                completion(.failure(HandleError.notFound))
            default:
                completion(.failure(HandleError.connectionError))
            }
        }
    }
    
    func requestPinPost(_ postId: String, type: AmityPostFeedType, isPinned: Bool, _ completion: @escaping(Result<Void, Error>) -> ()) {
        var domainURL = ""
        if let envKey = AmityUIKitManager.env["env_key"] as? String {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: envKey)
        } else {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: "") // Go to default (UAT)
        }
        
        //  Set params body
        var paramsBody: [String:Any] = [:]
        switch type {
        case .communityFeed(let communityId):
            paramsBody = ["postId": postId, "targetId": communityId, "targetType": "community", "isPinned": isPinned]
        default:
            paramsBody = ["postId": postId, "targetType": "global", "isPinned": isPinned]
        }
        
        requestMeta.urlRequest = "\(domainURL)/pin-post"
        requestMeta.header = [["Content-Type": "application/json",
                               "Accept": "application/json",
                               "Authorization": "Bearer \(currentUserToken)"]]
        requestMeta.method = .post
        requestMeta.encoding = .jsonEncoding
        requestMeta.params = paramsBody
        
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            
            // Print the JSON response
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []),
               let jsonData = try? JSONSerialization.data(withJSONObject: jsonResponse, options: []),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("-------> JSON Response: \(jsonString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                completion(.success(()))
            case 400...499:
                completion(.failure(HandleError.notFound))
            default:
                completion(.failure(HandleError.connectionError))
            }
        }
    }
}
