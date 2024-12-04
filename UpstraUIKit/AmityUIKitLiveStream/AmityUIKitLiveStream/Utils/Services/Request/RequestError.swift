//
//  RequestError.swift
//  Service
//
//  Created by PrInCeInFiNiTy on 28/6/2566 BE.
//

import Foundation

protocol OurErrorProtocol: LocalizedError {

    var errorMessage: String { get }
    var errorCode: Int { get }
}

struct RequestError:OurErrorProtocol {
    
    let errorCode: Int
    let errorMessage: String
    
    init(errorCode: Int = 0, errorMessage: String = "") {
        self.errorCode = errorCode
        self.errorMessage = errorMessage
    }
    
}

enum HandleError: Error {
    case connectionError, notFound, JsonDecodeError
}
