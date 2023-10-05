//
//  URLEnpointManager.swift
//  Service
//
//  Created by PrInCeInFiNiTy on 28/6/2566 BE.
//

import Foundation

struct DomainManager {
    
    struct Domain {
        // MARK: Custom API
        // [Custom for ONE Krungthai] -> Enumuration of domain url of custom API by env
        private enum CustomAPI: String {
            case DEV = "https://one-ktb-apidev.convolab.ai"
            case UAT = "https://one-ktb-apiuat.convolab.ai"
            case PRODUCTION = "https://one-ktb-api.convolab.ai"
        }
        
        // [Custom for ONE Krungthai] -> Get domain of custom API functoon by env from env_key of AmityUIKitManager.env or AmityUIKitManagerInternal.shared.env
        static func getDomainURLCustomAPI(env: String) -> String {
            switch env {
            case "DEV":
                return CustomAPI.DEV.rawValue
            case "UAT":
                return CustomAPI.UAT.rawValue
            case "PRODUCTION":
                return CustomAPI.PRODUCTION.rawValue
            default:
                return CustomAPI.UAT.rawValue // Set UAT to default
            }
        }
        
        // MARK: Main API
        // [Custom for ONE Krungthai] -> Enumuration of domain url of main API
        enum MainAPI: String {
            case US = "https://api.us.amity.co"
            case EU = "https://api.eu.amity.co"
            case SG = "https://api.sg.amity.co"
        }
        
        // [Custom for ONE Krungthai] -> Get domain of main API function by region
        static func getDomainURLMainAPI(region: MainAPI) -> String {
            return region.rawValue
        }
    }
    
}
