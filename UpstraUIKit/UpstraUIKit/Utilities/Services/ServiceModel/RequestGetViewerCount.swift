//
//  RequestGetViewerCount.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 24/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation

struct RequestGetViewerCount {
    
    let requestMeta = BaseRequestMeta()
    let currentUserToken = AmityUIKitManager.currentUserToken
    var streamId: String = ""
    
    func request(postId: String, viewerUserId: String, viewerDisplayName: String, isTrack: Bool, streamId: String, _ completion: @escaping(Result<ResponseGetViewerCountModel,Error>) -> ()) {
        var domainURL = ""
        if let envKey = AmityUIKitManager.env["env_key"] as? String {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: envKey)
        } else {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: "") // Go to default (UAT)
        }
        
        requestMeta.method = .post
        requestMeta.urlRequest = "\(domainURL)/viewerCount"
        requestMeta.encoding = .jsonEncoding
        requestMeta.params = ["postId": postId, "userId": viewerUserId, "displayName": viewerDisplayName, "isTrack": isTrack, "streamId": streamId]
        requestMeta.header = [
            ["Content-Type": "application/json"],
            ["Authorization": "Bearer \(currentUserToken)"]
        ]
                
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let dataModel = try? JSONDecoder().decode(ResponseGetViewerCountModel.self, from: data) else {
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
    
    func getViewerCount(postId: String, _ completion: @escaping(Result<ViewersModel,Error>) -> ()) {
        var domainURL = ""
        if let envKey = AmityUIKitManager.env["env_key"] as? String {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: envKey)
        } else {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: "") // Go to default (UAT)
        }

        requestMeta.method = .get
        requestMeta.urlRequest = "\(domainURL)/viewerCountRedis?postId=\(postId)"
        requestMeta.encoding = .urlEncoding
        requestMeta.header = [
            ["Authorization": "Bearer \(currentUserToken)"]
        ]
        
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let dataModel = try? JSONDecoder().decode(ViewersModel.self, from: data) else {
                    completion(.failure(HandleError.JsonDecodeError))
                    return
                }
                completion(.success(dataModel))
                
                let responseDataString = String(data: data, encoding: .utf8)
                print("[Livestream][getViewerCount] Response Data: \(responseDataString ?? "Unable to convert data to string")")
                
            case 400...499:
                completion(.failure(HandleError.notFound))
            default:
                completion(.failure(HandleError.connectionError))
            }
        }
    }
}
