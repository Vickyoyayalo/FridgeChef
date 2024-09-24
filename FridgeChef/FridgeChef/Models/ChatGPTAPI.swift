//
//  ChatGPTAPI.swift
//  TravelChatGPT
//
//  Created by Vickyhereiam on 2024/9/10.
//
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
        model: String = "gpt-3.5-turbo",
        systemPrompt: String,
        temperature: Double = 0.5,
        top_p: Double = 0.9
    ) {
        self.apiKey = apiKey
        self.model = model
        self.systemMessage = APIMessage(role: "system", content: systemPrompt)
        self.temperature = temperature
    }
    
    func sendMessage(_ text: String) async throws -> String {
        let requestMessages = generateMessages(from: text)
        
        // 打印发送给 API 的消息
        for message in requestMessages {
            print("\(message.role): \(message.content)")
        }
        
        let requestBody = Request(
            model: model,
            messages: requestMessages,
            temperature: temperature,
            top_p: 0.9,
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

        // 更新历史记录
        appendToHistoryList(userText: text, responseText: responseText)

        return responseText
    }

    private func generateMessages(from text: String) -> [APIMessage] {
        var messages = [systemMessage]
        let recentHistory = historyList.suffix(20)
        
        // 仅添加内容非空的消息
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

// 定义 APIMessage
struct APIMessage: Codable {
    let role: String
    let content: String
}



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
//    
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
//        model: String = "gpt-3.5-turbo",
//        systemPrompt: String = """
//    你是一個專業的廚師助手，能夠根據用戶提供的食材、圖片和描述，提供詳細的食譜和烹飪步驟。請用繁體中文回答，並盡可能提供完整的食譜，包括材料、步驟和提示。請按照以下格式回覆：
//    
//    🍳 **食譜名稱**
//    **食材：**
//    - 食材1
//    - 食材2
//    - ...
//    
//    **烹飪步驟：**
//    1. 步驟一
//    2. 步驟二
//    3. ...
//    """
//        ,
//        temperature: Double = 0.5 // 調低溫度
//    ) {
//        self.apiKey = apiKey
//        self.model = model
//        self.systemMessage = APIMessage(role: "system", content: systemPrompt)
//        self.temperature = temperature
//    }
//    
//    func sendMessage(_ text: String) async throws -> String {
//        let requestMessages = generateMessages(from: text)
//        let requestBody = Request(
//            model: model,
//            messages: requestMessages,
//            temperature: temperature,
//            top_p: 0.9,
//            max_tokens: 1500,
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
//        // 暫時移除格式化
//        appendToHistoryList(userText: text, responseText: responseText)
//        return responseText
//    }
//    
//    
//    // Example formatting function
//    func formatResponse(_ text: String) -> String {
//        // 解析回應文本以提取具體細節
//        let lines = text.split(separator: "\n").map { String($0) }
//        var formattedText = "🍳 食譜做法 🍳\n\n【食材】\n"
//        
//        // 假設回應文本中首先列出了食材
//        var ingredientsFinished = false
//        var steps: [String] = []
//        
//        for line in lines {
//            if line.lowercased().contains("步驟") {
//                ingredientsFinished = true
//            }
//            if !ingredientsFinished {
//                formattedText += "✅ \(line)\n"
//            } else {
//                steps.append(line)
//            }
//        }
//        
//        // 添加步驟到格式化文本
//        formattedText += "\n【烹飪步驟】\n"
//        for (index, step) in steps.enumerated() {
//            formattedText += "\(index + 1). \(step)\n"
//        }
//        
//        return formattedText
//    }
//    
//    
//    
//    //    func sendMessage(_ text: String) async throws -> String {
//    //        let requestMessages = generateMessages(from: text)
//    //        let requestBody = Request(
//    //            model: model,
//    //            messages: requestMessages,
//    //            temperature: temperature,
//    //            max_tokens: 1500,
//    //            stream: false
//    //        )
//    //        var urlRequest = self.urlRequest
//    //        urlRequest.httpBody = try JSONEncoder().encode(requestBody)
//    //
//    //        let (data, response) = try await urlSession.data(for: urlRequest)
//    //
//    //        guard let httpResponse = response as? HTTPURLResponse else {
//    //            throw "Invalid response"
//    //        }
//    //
//    //        guard 200...299 ~= httpResponse.statusCode else {
//    //            var errorMessage = "Bad Response: \(httpResponse.statusCode)"
//    //            if let errorResponse = try? jsonDecoder.decode(ErrorRootResponse.self, from: data).error {
//    //                errorMessage.append(",\n\(errorResponse.message)")
//    //            }
//    //            throw errorMessage
//    //        }
//    //
//    //        let completionResponse = try jsonDecoder.decode(CompletionResponse.self, from: data)
//    //        guard let responseText = completionResponse.choices.first?.message.content else {
//    //            throw "No response from assistant"
//    //        }
//    //
//    //        appendToHistoryList(userText: text, responseText: responseText)
//    //        return responseText
//    //    }
//    //
//    private func generateMessages(from text: String) -> [APIMessage] {
//        var messages = [systemMessage]
//        let recentHistory = historyList.suffix(20) // 保留最近的歷史訊息
//        messages += recentHistory
//        messages.append(APIMessage(role: "user", content: text))
//        
//        // 打印訊息以進行調試
//        for message in messages {
//            print("\(message.role): \(message.content)")
//        }
//        
//        return messages
//    }
//    
//    
//    private func appendToHistoryList(userText: String, responseText: String) {
//        historyList.append(APIMessage(role: "user", content: userText))
//        historyList.append(APIMessage(role: "assistant", content: responseText))
//        
//        // 限制歷史訊息數量，例如保留最近 10 條
//        if historyList.count > 20 {
//            historyList.removeFirst(historyList.count - 20)
//        }
//    }
//    
//    
//    
//    // 定义请求和响应结构体
//    struct Request: Codable {
//        let model: String
//        let messages: [APIMessage]
//        let temperature: Double
//        let top_p: Double // 新增 top_p 參數
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

//// 用于界面的消息结构体
//struct Message: Identifiable {
//    var id: UUID = UUID()
//    let role: ChatGPTRole
//    let content: String?
//    let image: UIImage?
//}
//
//// 聊天角色枚举
//enum ChatGPTRole: String {
//    case system
//    case user
//    case assistant
//}
//
//// 用于 API 通信的消息结构体
//struct APIMessage: Codable {
//    let role: String
//    let content: String
//}
