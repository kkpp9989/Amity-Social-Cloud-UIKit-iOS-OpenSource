//
//  RequestCustomSettings.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 10/1/2567 BE.
//  Copyright © 2567 BE Amity. All rights reserved.
//

import Foundation

enum ConfigId: String {
    case DEV = "-" // Don't have value
    case UAT = "63e3b8045a454a6dca905d40"
    case PRODUCTION = "64b52b8becf00f80902047cf"
}

struct RequestCustomSettings {

    let requestMeta = BaseRequestMeta()
    let currentUserToken = AmityUIKitManager.currentUserToken
    
    private func getConfigId(env: String) -> String {
        switch env {
        case "DEV":
            return ConfigId.DEV.rawValue
        case "UAT":
            return ConfigId.UAT.rawValue
        case "PRODUCTION":
            return ConfigId.PRODUCTION.rawValue
        default:
            return ConfigId.UAT.rawValue // Set UAT to default
        }
    }
    
    func requestLimitFileSizeSetting(completion: @escaping(Result<LimitFileSizeSettingModel,Error>) -> ()) {
        var domainURL = ""
        var configId = ""
        if let envKey = AmityUIKitManager.env["env_key"] as? String {
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: envKey)
            configId = getConfigId(env: envKey)
        } else {
            // Set to default (UAT)
            domainURL = DomainManager.Domain.getDomainURLCustomAPI(env: "")
            configId = getConfigId(env: "")
        }
        
        requestMeta.method = .get
        requestMeta.urlRequest = "\(domainURL)/fileSize?configId=\(configId)"
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
                guard let dataModel = try? JSONDecoder().decode(LimitFileSizeSettingModel.self, from: data) else {
                    logErrorDeCodeData(data: data)
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

    func logErrorDeCodeData(data: Data) {
        do {
            let _ = try JSONDecoder().decode(AmitySearchMessagesModel.self, from: data)
        } catch {
            print("[RequestCustomSettings] Parsing Error : \(String(describing: error))")
        }
    }
}
