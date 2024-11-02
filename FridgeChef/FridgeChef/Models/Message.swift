//
//  Message.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/11/2.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    let role: ChatGPTRole
    let content: String?
    var imageURL: String?
    let timestamp: Date
    var parsedRecipe: ParsedRecipe?
    
    enum CodingKeys: String, CodingKey {
        case id
        case role
        case content
        case imageURL
        case timestamp
        case parsedRecipe
    }
}
