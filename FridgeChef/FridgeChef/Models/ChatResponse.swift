//
//  ChatResponse.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/22.
//

import Foundation

struct ChatResponse: Codable {
    var id: String
    var object: String
    var created: Int
    var model: String
    var choices: [Choice]
    
    struct Choice: Codable {
        var text: String
    }
}

struct ChatRequest: Codable {
    var model: String
    var prompt: String
    var maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case model
        case prompt
        case maxTokens = "max_tokens"
    }
}

func sendMessageToChatGPT(message: String, completion: @escaping (String) -> Void) {
    guard let url = URL(string: "https://api.openai.com/v1/completions") else {
        print("Invalid URL")
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer sk-8VrzLltl-TexufDVK8RWN-GVvWLusdkCjGi9lKNSSkT3BlbkFJMryR2KSLUPFRKb5VCzGPXJGI8s-8bUt9URrmdfq0gA", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let payload = ChatRequest(model: "text-davinci-002", prompt: message, maxTokens: 150)

    do {
        let jsonData = try JSONEncoder().encode(payload)
        request.httpBody = jsonData
    } catch {
        print("Error encoding payload: \(error)")
        return
    }

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print("Error: \(error?.localizedDescription ?? "Unknown error")")
            return
        }

        do {
            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
            let responseText = chatResponse.choices.first?.text ?? "No response"
            DispatchQueue.main.async {
                completion(responseText)
            }
        } catch {
            print("Failed to decode response: \(error)")
        }
    }
    task.resume()
}

