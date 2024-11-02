//
//  KeychainManager.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/11/1.
//

import KeychainSwift

class KeychainManager {
    
    private let keychain = KeychainSwift()
    static let shared = KeychainManager()
    
    private init() {}
    
    @discardableResult
    func saveApiKey(_ apiKey: String, forKey key: String) -> Bool {
        return keychain.set(apiKey, forKey: key)
    }
    
    func getApiKey(forKey key: String) -> String? {
        return keychain.get(key)
    }
    
    func deleteApiKey(forKey key: String) {
        keychain.delete(key)
    }
}


