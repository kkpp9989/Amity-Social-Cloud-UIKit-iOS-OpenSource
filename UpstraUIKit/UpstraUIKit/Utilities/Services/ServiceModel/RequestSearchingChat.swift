//
//  RequestSearchingChat.swift
//  AmityUIKit
//
//  Created by GuIDe'MacbookAmityHQ on 10/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import Foundation

struct RequestSearchingChat {
    
    let requestMeta = BaseRequestMeta()
    let currentUserToken = AmityUIKitManager.currentUserToken
    let apiKey = AmityUIKitManagerInternal.shared.apiKey
    let userId = AmityUIKitManagerInternal.shared.currentUserId
    var keyword: String = ""
    var size: Int = 20
    var from: Int = 0
    
    func requestSearchMessages(_ completion: @escaping(Result<[String],Error>) -> ()) {
        let domainURL = "https://beta.amity.services"
        requestMeta.urlRequest = "\(domainURL)/search/messages"
        requestMeta.header = [["Content-Type": "application/json",
                               "Accept": "application/json",
                               "Authorization": "Bearer \(currentUserToken)"]]
        requestMeta.method = .post
        requestMeta.encoding = .jsonEncoding
        requestMeta.params = ["query": ["text": keyword], "from": from, "size": size, "apiKey": apiKey, "userId": userId]
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure(HandleError.notFound))
                return
            }
            switch httpResponse.statusCode {
            case 200:
                guard let dataModel = try? JSONDecoder().decode(AmitySearchMessagesModel.self, from: data) else {
                    completion(.failure(HandleError.JsonDecodeError))
                    return
                }
                completion(.success(dataModel.messageIDS))
            case 400...499:
                completion(.failure(HandleError.notFound))
            default:
                completion(.failure(HandleError.connectionError))
            }
        }
    }
    
}
