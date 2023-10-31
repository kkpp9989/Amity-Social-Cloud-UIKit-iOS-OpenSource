//
//  AmityTempSendFileMessageData.swift
//  AmityUIKit
//
//  Created by Thanaphat Thanawatpanya on 31/10/2566 BE.
//  Copyright © 2566 BE Amity. All rights reserved.
//

import UIKit

class AmityTempSendFileMessageData {
    static let shared = AmityTempSendFileMessageData()
    private(set) var data: [String: URL] = [:]
    
    private var defaultTempFolderURL: URL? {
        guard let defaultURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let tempFolderName = "temp"
        let tempFolderURL = defaultURL.appendingPathComponent(tempFolderName)
        
        return tempFolderURL
    }
    
    func add(currentFileURL: URL) {
        guard let defaultTempFolderURL = defaultTempFolderURL else { return }
        
        do {
            // Get temp file URL
            let filename = currentFileURL.lastPathComponent
            let tempFileURL = defaultTempFolderURL.appendingPathComponent(filename)
                        
            // Check file exist
            if FileManager.default.fileExists(atPath: tempFileURL.path) {
                data[filename] = tempFileURL
                Log.add(#"[UIKit][File] cache file "\#(filename)" to temp folder success (file exist) | path : \#(tempFileURL.path)"#)
                return
            }
            
            // Create temp folder
            try FileManager.default.createDirectory(at: defaultTempFolderURL, withIntermediateDirectories: true)
            
            // Copy file to temp folder
            try FileManager.default.copyItem(at: currentFileURL, to: tempFileURL)
            
            // Add path data to shared object
            data[filename] = tempFileURL
            
            Log.add(#"[UIKit][File] cache file "\#(filename)" to temp folder success | path : \#(tempFileURL.path)"#)
        } catch {
            Log.add(#"[UIKit][File] cache file "\#(currentFileURL.lastPathComponent)" to temp folder fail with error : \#(error.localizedDescription)"#)
        }
    }
    
    func remove(fileName: String) {
        do {
            // Get URL data
            guard let tempFileURL = data[fileName] else { return }
            
            // Delete cache file from temp folder
            try FileManager.default.removeItem(at: tempFileURL)
            
            // Delete path data from shared object
            data.removeValue(forKey: fileName)
            
            Log.add(#"[UIKit][File] delete cache file "\#(fileName)" from temp folder success | path: \#(tempFileURL.path)"#)
        } catch {
            Log.add(#"[UIKit][File] delete cache file "\#(fileName)" from temp folder fail with error : \#(error.localizedDescription)"#)
        }
    }
    
    func removeAll() {
        guard let defaultTempFolderURL = defaultTempFolderURL else { return }
        
        do {
            // Delete temp folder
            try FileManager.default.removeItem(at: defaultTempFolderURL)
            
            // Delete path data from shared object
            data.removeAll()
            
            Log.add("[UIKit][File] delete temp folder success")
        } catch {
            Log.add("[UIKit][File] delete temp folder fail with error : \(error.localizedDescription)")
        }
        
    }
}
