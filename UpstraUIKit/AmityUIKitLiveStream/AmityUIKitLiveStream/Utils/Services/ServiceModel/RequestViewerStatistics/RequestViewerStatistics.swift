//
//  RequestViewerStatistics.swift
//  AmityUIKitLiveStream
//
//  Created by Thanaphat Thanawatpanya on 20/7/2566 BE.
//

import Foundation
import AmityUIKit

struct RequestViewerStatistics {
    
    let requestMeta = BaseRequestMeta()
    let currentUserToken = AmityUIKitManager.currentUserToken
    var streamId: String = ""
    
    func sendViewerStatistics(postId: String, viewerUserId: String, viewerDisplayName: String, isTrack: Bool, streamId: String, _ completion: @escaping(Result<ViewerStatisticsModel,Error>) -> ()) {
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
        
//        print("[Livestream][Custom][Send viewer satistics][\(Date())] Start request send viewer statistics API with url: \(requestMeta.urlRequest) | data: \(requestMeta.params) | header: \(requestMeta.header)")
        
        NetworkManager().request(requestMeta) { (data, response, error) in
            guard let data = data, let httpResponse = response as? HTTPURLResponse, error == nil else {
                completion(.failure("Not data" as! Error))
                return
            }

//            print("[Livestream][Custom][Send viewer satistics][\(Date())] Request send viewer statistics API success with response status code: \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200:
                guard let dataModel = try? JSONDecoder().decode(ViewerStatisticsModel.self, from: data) else {
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
