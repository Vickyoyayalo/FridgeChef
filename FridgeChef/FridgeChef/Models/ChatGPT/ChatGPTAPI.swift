//
//  ChatGPTAPI.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/10.
//

import Foundation

class ChatGPTAPI {
    
    private let apiKey: String
    private let model: String
    private var systemMessage: APIMessage
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
        model: String = "gpt-4", // 使用 GPT-4 模型
        systemPrompt: String,
        temperature: Double = 0.5,
        top_p: Double = 0.9
    ) {
        self.apiKey = apiKey
        self.model = model
        self.systemMessage = APIMessage(role: "system", content: systemPrompt)
        self.temperature = temperature
    }
    
    // 新增方法來更新系統提示
    func updateSystemPrompt(_ newPrompt: String) {
        self.systemMessage = APIMessage(role: "system", content: newPrompt)
    }
    
    // 修改 sendMessage 函數以包含更新後的 systemMessage
        func sendMessage(_ text: String) async throws -> String {
            var messages = [systemMessage]
            let recentHistory = historyList.suffix(20)
            let validHistory = recentHistory.filter { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            messages += validHistory
            messages.append(APIMessage(role: "user", content: text))
            
            // 打印發送給 API 的消息
            for message in messages {
                print("\(message.role): \(message.content ?? "")")
            }
            
            let requestBody = Request(
                model: model,
                messages: messages,
                temperature: temperature,
                top_p: 0.9,
                max_tokens: 2500,
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

            // 更新歷史記錄
            appendToHistoryList(userText: text, responseText: responseText)

            return responseText
        }

    // 修改生成 URLRequest 的部分，以使用更新後的 systemMessage
       private func generateRequestBody(messages: [APIMessage]) -> Data? {
           let request = Request(
               model: model,
               messages: messages,
               temperature: temperature,
               top_p: 0.9,
               max_tokens: 2500,
               stream: false
           )
           return try? JSONEncoder().encode(request)
       }
    private func generateMessages(from text: String) -> [APIMessage] {
        var messages = [systemMessage]
        let recentHistory = historyList.suffix(20)
        
        let validHistory = recentHistory.filter { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        messages += validHistory
        messages.append(APIMessage(role: "user", content: text))
        
        return messages
    }

    func appendToHistoryList(userText: String?, responseText: String?) {
        if let userText = userText, !userText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            historyList.append(APIMessage(role: "user", content: userText))
        }
        if let responseText = responseText, !responseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            historyList.append(APIMessage(role: "assistant", content: responseText))
        }
        
        // 限制历史记录的大小
        if historyList.count > 20 {
            historyList.removeFirst(historyList.count - 20)
        }
    }

    // 定义请求和响应结构体
    struct Request: Codable {
        let model: String
        let messages: [APIMessage]
        let temperature: Double
        let top_p: Double
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


struct APIMessage: Codable {
    let role: String
    let content: String
}


//import Foundation
//
//class ChatGPTAPI {
//    
//    private let apiKey: String
//    private let model: String
//    private let systemMessage: APIMessage
//    private let temperature: Double
//    private var historyList: [APIMessage] = []
//    private let urlSession = URLSession.shared
//    private var urlRequest: URLRequest {
//        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
//        var urlRequest = URLRequest(url: url)
//        urlRequest.httpMethod = "POST"
//        headers.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }
//        return urlRequest
//    }
//    private var headers: [String: String] {
//        [
//            "Content-Type": "application/json",
//            "Authorization": "Bearer \(apiKey)"
//        ]
//    }
//    private let jsonDecoder = JSONDecoder()
//    
//    init(
//        apiKey: String,
//        model: String = "gpt-3.5-turbo", /*gpt-4o*//*gpt-3.5-turbo*/
//        systemPrompt: String,
//        temperature: Double = 0.5,
//        top_p: Double = 0.9
//    ) {
//        self.apiKey = apiKey
//        self.model = model
//        self.systemMessage = APIMessage(role: "system", content: systemPrompt)
//        self.temperature = temperature
//    }
//    
//    func sendMessage(_ text: String) async throws -> String {
//        let requestMessages = generateMessages(from: text)
//        
//        // 打印发送给 API 的消息
//        for message in requestMessages {
//            print("\(message.role): \(message.content)")
//        }
//        
//        let requestBody = Request(
//            model: model,
//            messages: requestMessages,
//            temperature: temperature,
//            top_p: 0.9,
//            max_tokens: 2500,
//            stream: false
//        )
//        var urlRequest = self.urlRequest
//        urlRequest.httpBody = try JSONEncoder().encode(requestBody)
//
//        let (data, response) = try await urlSession.data(for: urlRequest)
//
//        guard let httpResponse = response as? HTTPURLResponse else {
//            throw "Invalid response"
//        }
//
//        guard 200...299 ~= httpResponse.statusCode else {
//            var errorMessage = "Bad Response: \(httpResponse.statusCode)"
//            if let errorResponse = try? jsonDecoder.decode(ErrorRootResponse.self, from: data).error {
//                errorMessage.append(",\n\(errorResponse.message)")
//            }
//            throw errorMessage
//        }
//
//        let completionResponse = try jsonDecoder.decode(CompletionResponse.self, from: data)
//        guard let responseText = completionResponse.choices.first?.message.content else {
//            throw "No response from assistant"
//        }
//
//        // 更新历史记录
//        appendToHistoryList(userText: text, responseText: responseText)
//
//        return responseText
//    }
//
//    private func generateMessages(from text: String) -> [APIMessage] {
//        var messages = [systemMessage]
//        let recentHistory = historyList.suffix(20)
//        
//        // 仅添加内容非空的消息
//        let validHistory = recentHistory.filter { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
//        messages += validHistory
//        messages.append(APIMessage(role: "user", content: text))
//        
//        return messages
//    }
//
//    func appendToHistoryList(userText: String?, responseText: String?) {
//        if let userText = userText, !userText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//            historyList.append(APIMessage(role: "user", content: userText))
//        }
//        if let responseText = responseText, !responseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//            historyList.append(APIMessage(role: "assistant", content: responseText))
//        }
//        
//        // 限制历史记录的大小
//        if historyList.count > 20 {
//            historyList.removeFirst(historyList.count - 20)
//        }
//    }
//
//    // 定义请求和响应结构体
//    struct Request: Codable {
//        let model: String
//        let messages: [APIMessage]
//        let temperature: Double
//        let top_p: Double
//        let max_tokens: Int
//        let stream: Bool
//    }
//    
//    struct CompletionResponse: Decodable {
//        let choices: [Choice]
//    }
//    
//    struct Choice: Decodable {
//        let message: APIMessage
//    }
//    
//    struct ErrorRootResponse: Decodable {
//        let error: ErrorResponse
//    }
//    
//    struct ErrorResponse: Decodable {
//        let message: String
//        let type: String?
//        let param: String?
//        let code: String?
//    }
//}
//
//extension String: LocalizedError {
//    public var errorDescription: String? { return self }
//}
//
//// 定义 APIMessage
//struct APIMessage: Codable {
//    let role: String
//    let content: String
//}
