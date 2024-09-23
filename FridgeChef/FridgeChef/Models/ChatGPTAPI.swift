//
//  ChatGPTAPI.swift
//  TravelChatGPT
//
//  Created by Vickyhereiam on 2024/9/10.
//
import UIKit
import SwiftUI
import Foundation

class ChatGPTAPI {
    
    private let apiKey: String
    private let model: String
    private let systemMessage: APIMessage
    private let temperature: Double
    private var historyList: [APIMessage] = []
    private let urlSession = URLSession.shared
    private var urlRequest: URLRequest {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        headers.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }
        return urlRequest
    }
    private var headers: [String: String] {
        [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
    }
    private let jsonDecoder = JSONDecoder()
    
    init(
        apiKey: String,
        model: String = "gpt-4",
        systemPrompt: String = "你是一個專業的廚師助手，能夠根據用戶提供的食材、圖片和描述，提供詳細的食譜和烹飪步驟。請用繁體中文回答，並盡可能提供完整的食譜，包括材料、步驟和提示。",
        temperature: Double = 1
    ) {
        self.apiKey = apiKey
        self.model = model
        self.systemMessage = APIMessage(role: "system", content: systemPrompt)
        self.temperature = temperature
    }
    
    func sendMessage(_ text: String) async throws -> String {
        let requestMessages = generateMessages(from: text)
        let requestBody = Request(
            model: model,
            messages: requestMessages,
            temperature: temperature,
            max_tokens: 1500,
            stream: false
        )
        var urlRequest = self.urlRequest
        urlRequest.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw "Invalid response"
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            var errorMessage = "Bad Response: \(httpResponse.statusCode)"
            if let errorResponse = try? jsonDecoder.decode(ErrorRootResponse.self, from: data).error {
                errorMessage.append(",\n\(errorResponse.message)")
            }
            throw errorMessage
        }
        
        let completionResponse = try jsonDecoder.decode(CompletionResponse.self, from: data)
        guard let responseText = completionResponse.choices.first?.message.content else {
            throw "No response from assistant"
        }
        
        appendToHistoryList(userText: text, responseText: responseText)
        return responseText
    }
    
    private func generateMessages(from text: String) -> [APIMessage] {
        var messages = [systemMessage] + historyList
        messages.append(APIMessage(role: "user", content: text))
        return messages
    }
    
    private func appendToHistoryList(userText: String, responseText: String) {
        historyList.append(APIMessage(role: "user", content: userText))
        historyList.append(APIMessage(role: "assistant", content: responseText))
    }
    
    // 定义请求和响应结构体
    struct Request: Codable {
        let model: String
        let messages: [APIMessage]
        let temperature: Double
        let max_tokens: Int
        let stream: Bool
    }
    
    struct CompletionResponse: Decodable {
        let choices: [Choice]
    }
    
    struct Choice: Decodable {
        let message: APIMessage
    }
    
    struct ErrorRootResponse: Decodable {
        let error: ErrorResponse
    }
    
    struct ErrorResponse: Decodable {
        let message: String
        let type: String?
        let param: String?
        let code: String?
    }
}

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}



// 用于界面的消息结构体
struct Message: Identifiable {
    var id: UUID = UUID()
    let role: ChatGPTRole
    let content: String?
    let image: UIImage?
}

// 聊天角色枚举
enum ChatGPTRole: String {
    case system
    case user
    case assistant
}

// 用于 API 通信的消息结构体
struct APIMessage: Codable {
    let role: String
    let content: String
}
