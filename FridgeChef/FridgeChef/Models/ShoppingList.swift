//
//  ShoppingList.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import Foundation
import FirebaseFirestore

struct ShoppingList: Identifiable, Codable {
    @DocumentID var id: String?
    var ingredientId: String // 參照 Ingredient ID
    var isPurchased: Bool // 是否已購買
    var priority: Int // 優先級

    init(id: String? = nil, ingredientId: String, isPurchased: Bool, priority: Int) {
        self.id = id
        self.ingredientId = ingredientId
        self.isPurchased = isPurchased
        self.priority = priority
    }
}

