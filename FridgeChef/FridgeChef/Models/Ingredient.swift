//
//  Ingredient.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import Foundation
import FirebaseFirestore

struct Ingredient: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var ingredientPhoto: [String] // 可以是食材照片的URL
    var quantity: Quantity // 自定義結構來表示數量和單位
    var category: [String] // 食材分類的陣列
    var expirationDate: Date // 有效期
    var storage: [String] // 存放的地方，如冰箱、冷凍等

    struct Quantity: Codable {
        var amount: String // 數量
        var unit: Double   // 單位
    }

    init(id: String? = nil, name: String, ingredientPhoto: [String], quantity: Quantity, category: [String], expirationDate: Date, storage: [String]) {
        self.id = id
        self.name = name
        self.ingredientPhoto = ingredientPhoto
        self.quantity = quantity
        self.category = category
        self.expirationDate = expirationDate
        self.storage = storage
    }
}

