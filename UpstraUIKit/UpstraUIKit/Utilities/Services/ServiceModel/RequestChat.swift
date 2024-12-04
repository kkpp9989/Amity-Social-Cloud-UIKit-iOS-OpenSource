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
    
    func requestSendMessage(channelId: String, message: AmityMessageModel, completion: @escaping(Result<Bool,Error>) -> ()) {
        let domainURL = "https://api.sg.amity.co"
        requestMeta.urlRequest = "\(domainURL)/api/v5/messages"
        requestMeta.header = [["Content-Type": "application/json",
                               "Accept": "application/json",
                               "Authorization": "Bearer \(currentUserToken)"]]
        requestMeta.method = .post
        requestMeta.encoding = .jsonEncoding
        
        var type: String = "text"
        switch message.messageType {
        case .text:
            type = "text"
        case .image:
            type = "image"
        case .audio:
            type = "audio"
        case.file:
            type = "file"
        case .video:
            type = "video"
        case .custom:
            type = "custom"
        @unknown default:
            break
        }
        var params: [String: Any] = ["messageFeedId": channelId, "dataType": type, "referenceId": message.messageId]
        
        if let fileId = message.object.fileId, !fileId.isEmpty {
            params["fileId"] = fileId
        }
        if let text = message.data?["text"] as? String, !text.isEmpty {
            params["data"] = ["text": text]
        }
        
        requestMeta.params = params
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            switch httpResponse.statusCode {
            case 200:
                completion(.success(true))
            case 400...499:
                completion(.failure(HandleError.notFound))
            default:
                completion(.failure(HandleError.connectionError))
            }
        }
        
    }
    
}
