//
//  APIKeyManager.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/11/2.
//

import Foundation

class APIKeyManager {
    static let shared = APIKeyManager()
    
    private init() {}
    
    func initializeAPIKeys() {
//        deleteOldApiKey(forKey: "SupermarketAPI_Key")
        initializeAPIKey(forKey: "API_KEY", plistName: "GoogleService-Info")
        initializeAPIKey(forKey: "OpenAIAPI_Key", plistName: "GoogleService-Info")
        initializeAPIKey(forKey: "SupermarketAPI_Key", plistName: "GoogleService-Info")
    }
    
    private func initializeAPIKey(forKey key: String, plistName: String) {
        if KeychainManager.shared.getApiKey(forKey: key) == nil {
            print("\(key) not found in Keychain. Attempting to read from plist.")
            if let path = Bundle.main.path(forResource: plistName, ofType: "plist"),
               let dict = NSDictionary(contentsOfFile: path),
               let apiKey = dict[key] as? String {
                let isSaved = KeychainManager.shared.saveApiKey(apiKey, forKey: key)
                if isSaved {
                    print("\(key) saved to Keychain.")
                } else {
                    print("Failed to save \(key) to Keychain.")
                }
            } else {
                print("\(key) not found in \(plistName).plist.")
            }
        } else {
            print("\(key) already exists in Keychain.")
        }
    }
    
    func getAPIKey(forKey key: String) -> String? {
        return KeychainManager.shared.getApiKey(forKey: key)
    }
    
//    private func deleteOldApiKey(forKey key: String) {
//        KeychainManager.shared.deleteApiKey(forKey: key)
//        print("Old API Key for \(key) has been deleted from Keychain.")
//    }
    
}
