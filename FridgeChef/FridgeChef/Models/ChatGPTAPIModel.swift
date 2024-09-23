//
//  ChatGPTAPIModel.swift
//  TravelChatGPT
//
//  Created by Vickyhereiam on 2024/9/10.
//

//import Foundation
//import SwiftUI
//
//struct Message: Identifiable {
//    var id: UUID = UUID()
//    let role: ChatGPTRole
//    let content: String?
//    let image: UIImage?
//}
//
//// 用于 API 通信的 APIMessage 结构体
//struct APIMessage: Codable {
//    let role: String
//    let content: String
//}
//
//
//enum CodingKeys: String, CodingKey {
//    case id
//    case role
//    case content
//    // 排除 image 属性
//}
//
//enum ChatGPTRole: String, Codable {
//    case system = "system"
//    case user = "user"
//    case assistant = "assistant"
//
//}
//
//
//struct Request: Codable {
//    let model: String
//    let messages: [APIMessage]
//    let temperature: Double
//    let max_tokens: Int
//    let stream: Bool
//}
//
//// MARK: - Resposne
//struct CompletionResponse: Decodable {
//    let choices: [Choice]
//}
//
//struct Choice: Decodable {
//    let message: APIMessage
//}
//
//struct ErrorRootResponse: Decodable {
//    let error: ErrorResponse
//}
//
//struct ErrorResponse: Decodable {
//    let message: String
//    let type: String?
//    let param: String?
//    let code: String?
//}
//
//
//// MARK: - Error
//struct ErrorRootResponse: Decodable {
//    let error: ErrorResponse
//}
//struct ErrorResponse: Decodable {
//    let message: String
//    let type: String?
//}
