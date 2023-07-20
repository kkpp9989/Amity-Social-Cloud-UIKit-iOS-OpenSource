//
//  RequestGetPost.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 19/7/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation

struct RequestGetPost {
    
    let requestMeta = BaseRequestMeta()
    let currentUserToken = AmityUIKitManager.currentUserToken
    var streamId: String = ""
    
    func requestPostIdByStreamId(_ streamId: String, _ completion: @escaping(Result<ResponseGetPostModel,Error>) -> ()) {
        var domainURL = ""
        if let envKey = AmityUIKitManager.env["env_key"] as? String {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: envKey)
        } else {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: "") // Go to default (UAT)
        }
        
        print("currentUserToken: \(currentUserToken)")
        
        requestMeta.urlRequest = "\(domainURL)/getPostId?streamId=\(streamId)"
        requestMeta.header = [["Authorization": "Bearer \(currentUserToken)"]]
        requestMeta.method = .get
        requestMeta.encoding = .urlEncoding
        
        print("[Post-detail][Custom][Get postId from streamId] Start request get postId by streamId API with url: \(requestMeta.urlRequest) | data: \(requestMeta.params) | header: \(requestMeta.header)")
        
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure("Not data" as! Error))
                return
            }
            print("[Post-detail][Custom][Get postId from streamId] Request get postId by streamId API with response status code: \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200:
                guard let dataModel = try? JSONDecoder().decode(ResponseGetPostModel.self, from: data) else {
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
