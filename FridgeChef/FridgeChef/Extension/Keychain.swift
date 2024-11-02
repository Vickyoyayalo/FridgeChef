//
//  Keychain.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/11/1.
//

import Foundation
import KeychainSwift

let keychain = KeychainSwift()

func initializeApiKey() {
    if keychain.get("OpenAIAPI_Key") == nil {
        print("API Key not found in Keychain. Attempting to read from plist.")
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let apiKey = dict["OpenAIAPI_Key"] as? String {
            keychain.set(apiKey, forKey: "OpenAIAPI_Key")
            print("API Key saved to Keychain.")
        } else {
            print("API Key not found in GoogleService-Info.plist.")
        }
    } else {
        print("API Key already exists in Keychain.")
    }
}


