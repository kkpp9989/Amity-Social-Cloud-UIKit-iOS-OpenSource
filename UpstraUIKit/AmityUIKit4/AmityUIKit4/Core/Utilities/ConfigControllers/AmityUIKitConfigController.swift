//
//  AmityUIKitConfigController.swift
//  AmityUIKit4
//
//  Created by Zay Yar Htun on 11/23/23.
//

import Foundation
import UIKit

class AmityUIKitConfigController {
    static let shared = AmityUIKitConfigController()
    private var config: [String: Any] = [:]
    private var excludedList: Set<String> = []
    
    private init() {
        configParser(configFile: "AmityUIKitConfig")
    }
    
    // MARK: Public Functions
    
    func isExcluded(configId: String) -> Bool {
        return excludedList.contains(configId)
    }
    
    
    func getTheme(configId: String? = nil) -> AmityThemeColor {
        let systemStyle = UIScreen.main.traitCollection.userInterfaceStyle
        let configStyle = AmityThemeStyle(rawValue: config["preferred_theme"] as? String ?? "light") ?? .light
        
        let style: AmityThemeStyle = configStyle == .system ? (systemStyle == .light ? .light : .dark) : (configStyle == .light ? .light : .dark)
        
        let fallbackTheme = style == .light ? lightTheme : darkTheme
        let globalTheme = getGlobalTheme(style) ?? fallbackTheme
        
        guard let configId else {
            return getThemeColor(theme: globalTheme, fallbackTheme: fallbackTheme)
        }
        
        let customizationConfig = config["customizations"] as? [String: Any]
        let id = configId.components(separatedBy: "/")
        guard id.count == 3 else { return getThemeColor(theme: globalTheme, fallbackTheme: fallbackTheme) }
        

        let pageTheme = customizationConfig?[keyPath: "\(id[0])/*/*.theme.\(style.rawValue)"] as? [String: Any]
        let componentTheme = customizationConfig?[keyPath: "*/\(id[1])/*.theme.\(style.rawValue)"] as? [String: Any]
        
        do {
            if let componentTheme {
                return try getThemeColor(theme: componentTheme.decode(AmityTheme.self), fallbackTheme: fallbackTheme)
            }
            
            if let pageTheme {
                return try getThemeColor(theme: pageTheme.decode(AmityTheme.self), fallbackTheme: fallbackTheme)
            }
        } catch {
            return getThemeColor(theme: globalTheme, fallbackTheme: fallbackTheme)
        }
        
        return getThemeColor(theme: globalTheme, fallbackTheme: fallbackTheme)
    }
    
    
    func getConfig(configId: String) -> [String: Any] {
        let id = configId.components(separatedBy: "/")
        
        guard id.count == 3, let customizationConfig = config["customizations"] as? [String: Any] else {
            return [:]
        }
        
        // normal config
        if let config = customizationConfig[configId] as? [String: Any] {
            return config
        }
        
        // wild card config
        if id[1] != "*" {
            // component wildcard config
            if let config = customizationConfig["*/\(id[1])/*"] as? [String: Any] {
                return config
            }
        } else if id[2] != "*" {
            // element wildcard config
            if let config = customizationConfig["*/*/\(id[2])"] as? [String: Any] {
                return config
            }
        }
        
        return [:]
    }
    
    // MARK: Private Functions
    
    private func getGlobalTheme(_ style: AmityThemeStyle) -> AmityTheme? {
        let globalTheme = config[keyPath: "theme.\(style.rawValue)"] as? [String: Any]
        do {
            return try globalTheme?.decode(AmityTheme.self)
        } catch {
            return nil
        }
    }
    
    
    private func getThemeColor(theme: AmityTheme, fallbackTheme: AmityTheme) -> AmityThemeColor {
        return AmityThemeColor(primaryColor: theme.primaryColor ?? fallbackTheme.primaryColor!,
                               secondaryColor: theme.secondaryColor ?? fallbackTheme.secondaryColor!,
                               baseColor: theme.baseColor ?? fallbackTheme.baseColor!,
                               baseColorShade1: theme.baseColorShade1 ?? fallbackTheme.baseColorShade1!,
                               baseColorShade2: theme.baseColorShade2 ?? fallbackTheme.baseColorShade2!,
                               baseColorShade3: theme.baseColorShade3 ?? fallbackTheme.baseColorShade3!,
                               baseColorShade4: theme.baseColorShade4 ?? fallbackTheme.baseColorShade4!,
                               alertColor: theme.alertColor ?? fallbackTheme.alertColor!,
                               backgroundColor: theme.backgroundColor ?? fallbackTheme.backgroundColor!)
    }
    
    
    private func configParser(configFile: String) {
        config = loadConfigFile(fileName: configFile)
        excludedList = Set(config["excludes"] as? [String] ?? [])
    }
    
    private func loadConfigFile(fileName: String) -> [String: Any] {
        if let path = AmityUIKit4Manager.bundle.path(forResource: fileName, ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let jsonResult = jsonResult as? Dictionary<String, AnyObject> {
                    return jsonResult
                }
            } catch {
                return [:]
            }
        }
        return [:]
    }
}