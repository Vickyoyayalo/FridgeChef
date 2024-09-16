//
//  ShoppingList.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import Foundation
import FirebaseFirestore

struct ShoppingList: Identifiable, Codable {
    @DocumentID var id: String? // Firestore 的文件 ID
    var ingredientId: String // 關聯的食材 ID
    var isPurchased: Bool // 是否已購買
    var priority: Int // 購物優先級

    init(id: String? = nil, ingredientId: String, isPurchased: Bool, priority: Int) {
        self.id = id
        self.ingredientId = ingredientId
        self.isPurchased = isPurchased
        self.priority = priority
    }
}
