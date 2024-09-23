//
//  ChatResponse.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/22.
//

//import Foundation
//
//struct ChatResponse: Codable {
//    var id: String
//    var object: String
//    var created: Int
//    var model: String
//    var choices: [Choice]
//    
//    struct Choice: Codable {
//        var text: String
//    }
//}
//
//struct ChatRequest: Codable {
//    var model: String
//    var messages: [Message]
//    var maxTokens: Int
//
//    enum CodingKeys: String, CodingKey {
//        case model
//        case messages
//        case maxTokens = "max_tokens"
//    }
//}
//
//func sendMessageToChatGPT(message: String, completion: @escaping (String) -> Void) {
//    guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
//        print("Invalid URL")
//        return
//    }
//
//    var request = URLRequest(url: url)
//    request.httpMethod = "POST"
//    request.addValue("Bearer YOUR_ACTUAL_API_KEY", forHTTPHeaderField: "Authorization")  // 請替換 YOUR_ACTUAL_API_KEY 為你的實際 API 密鑰
//    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//
//    let userMessage = Message(role: "user", content: message)
//    let payload = ChatRequest(model: "gpt-3.5-turbo", messages: [userMessage], maxTokens: 150)
//
//    do {
//        let jsonData = try JSONEncoder().encode(payload)
//        request.httpBody = jsonData
//        print("Request body: \(String(data: jsonData, encoding: .utf8) ?? "Invalid JSON data")")
//    } catch {
//        print("Error encoding payload: \(error)")
//        return
//    }
//
//    let task = URLSession.shared.dataTask(with: request) { data, response, error in
//        guard let httpResponse = response as? HTTPURLResponse else {
//            print("Error: No valid HTTP response")
//            return
//        }
//
//        guard httpResponse.statusCode == 200 else {
//            print("HTTP Status: \(httpResponse.statusCode)")
//            if let data = data, let body = String(data: data, encoding: .utf8) {
//                print("Response body: \(body)")
//            }
//            return
//        }
//
//        guard let data = data else {
//            print("No data received")
//            return
//        }
//
//        do {
//            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
//            let responseText = chatResponse.choices.first?.text ?? "No response"
//            DispatchQueue.main.async {
//                completion(responseText)
//            }
//        } catch {
//            print("Failed to decode response: \(error)")
//        }
//    }
//    task.resume()
//}
