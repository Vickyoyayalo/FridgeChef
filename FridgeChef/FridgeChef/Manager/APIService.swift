//
//  APIService.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/11/1.
//

import Foundation
import KeychainSwift

class APIService {
    private let keychain = KeychainSwift()
    private let apiKeyName = "OpenAIAPI_Key"
    
    // Method to send message using API Key stored in Keychain
    func sendMessage(with message: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Get API Key from Keychain
        guard let apiKey = keychain.get(apiKeyName), !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "API Key Error", code: 401, userInfo: [NSLocalizedDescriptionKey: "API Key is missing or invalid."])))
            return
        }
        
        // Create URL Request with API Key
        let url = URL(string: "https://api.example.com/sendMessage")! // Replace with your actual API endpoint
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        
        let body: [String: Any] = ["message": message]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        // Make the network request
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let data = data, let responseText = String(data: data, encoding: .utf8) {
                completion(.success(responseText))
            }
        }.resume()
    }
}
