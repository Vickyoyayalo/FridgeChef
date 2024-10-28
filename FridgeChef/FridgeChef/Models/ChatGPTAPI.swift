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
        model: String = "gpt-4",
        systemPrompt: String,
        temperature: Double = 0.5,
        top_p: Double = 0.9
    ) {
        self.apiKey = apiKey
        self.model = model
        self.systemMessage = APIMessage(role: "system", content: systemPrompt)
        self.temperature = temperature
    }
    
    func updateSystemPrompt(_ newPrompt: String) {
        self.systemMessage = APIMessage(role: "system", content: newPrompt)
    }
    
        func sendMessage(_ text: String) async throws -> String {
            var messages = [systemMessage]
            let recentHistory = historyList.suffix(20)
            let validHistory = recentHistory.filter { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            messages += validHistory
            messages.append(APIMessage(role: "user", content: text))
            
            for message in messages {
                print("\(message.role): \(message.content)")
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

            appendToHistoryList(userText: text, responseText: responseText)

            return responseText
        }

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
        
        if historyList.count > 20 {
            historyList.removeFirst(historyList.count - 20)
        }
    }

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
