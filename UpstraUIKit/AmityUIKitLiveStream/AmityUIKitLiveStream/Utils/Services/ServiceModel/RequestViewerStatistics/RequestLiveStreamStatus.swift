//
//  RequestLiveStreamStatus.swift
//  AmityUIKitLiveStream
//
//  Created by GuIDe'MacbookAmityHQ on 22/12/2566 BE.
//

import Foundation
import AmityUIKit

struct RequestLiveStreamStatus {
    
    let requestMeta = BaseRequestMeta()
    let currentUserToken = AmityUIKitManager.currentUserToken
    var streamId: String = ""
    
    func request(postId: String, streamId: String, isLive: Bool, _ completion: @escaping(Result<Bool,Error>) -> ()) {
        var domainURL = ""
        if let envKey = AmityUIKitManager.env["env_key"] as? String {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: envKey)
        } else {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: "") // Go to default (UAT)
        }
        
        requestMeta.method = .post
        requestMeta.urlRequest = "\(domainURL)/live-status"
        requestMeta.encoding = .jsonEncoding
        requestMeta.params = ["postId": postId, "streamId": streamId, "isLive": isLive]
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
                completion(.success(true))
            case 400...499:
                completion(.failure(HandleError.notFound))
            default:
                completion(.failure(HandleError.connectionError))
            }
        }
    }
}
