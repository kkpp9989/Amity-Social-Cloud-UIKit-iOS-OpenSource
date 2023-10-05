//
//  RequestChat.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 4/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation

struct RequestChat {
    
    let requestMeta = BaseRequestMeta()
    let currentUserToken = AmityUIKitManager.currentUserToken
    var streamId: String = ""
    
    func requestDeleteChat(channelId: String, _ completion: @escaping(Result<ResponseDeleteChannelModel,Error>) -> ()) {
        var domainURL = DomainManager.Domain.getDomainURLMainAPI(region: .SG)
        
        requestMeta.urlRequest = "\(domainURL)/api/v3/channels/\(channelId)"
        requestMeta.header = [["Authorization": "Bearer \(currentUserToken)"]]
        requestMeta.method = .delete
        requestMeta.encoding = .urlEncoding
        
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let dataModel = try? JSONDecoder().decode(ResponseDeleteChannelModel.self, from: data) else {
                    completion(.failure(HandleError.JsonDecodeError))
                    return
                }
                completion(.success(dataModel))
            case 403:
                guard let dataModel = try? JSONDecoder().decode(ResponseDeleteChannelModel.self, from: data) else {
                    completion(.failure(HandleError.JsonDecodeError))
                    return
                }
                print("[Chat][Delete chat] Can't delete channelId \(channelId) because of permission denied (403)")
                completion(.failure(HandleError.permissionDenied))
            case 404:
                guard let dataModel = try? JSONDecoder().decode(ResponseDeleteChannelModel.self, from: data) else {
                    completion(.failure(HandleError.JsonDecodeError))
                    return
                }
                print("[Chat][Delete chat] Can't delete channelId \(channelId) because of resource not found (404)")
                completion(.failure(HandleError.notFound))
            case 429:
                guard let dataModel = try? JSONDecoder().decode(ResponseDeleteChannelModel.self, from: data) else {
                    completion(.failure(HandleError.JsonDecodeError))
                    return
                }
                print("[Chat][Delete chat] Can't delete channelId \(channelId) because of rate limit exceeded (429)")
                completion(.failure(HandleError.rateLimitExceed))
            default:
                print("[Chat][Delete chat] Can't delete channelId \(channelId) because of connection or unexpected error")
                completion(.failure(HandleError.connectionError))
            }
        }
        
    }
    
}
