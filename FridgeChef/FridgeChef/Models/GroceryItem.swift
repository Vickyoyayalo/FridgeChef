//
//  ShoppingList.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import Foundation
import FirebaseFirestore

struct GroceryItem: Identifiable {
    let id = UUID()
    let name: String
    let isSuggested: Bool
}


//struct GroceryItem: Identifiable, Codable {
//    @DocumentID var id: String? // Firestore 的文件 ID
//    var name: String
//    var isSuggested: Bool
//    var priority: Int
//    
//    init(id: String? = nil, ingredientId: String, isPurchased: Bool, priority: Int) {
//        self.id = id
//        self.name = name
//        self.isSuggested = isSuggested
//        self.priority = priority
//    }
//}
