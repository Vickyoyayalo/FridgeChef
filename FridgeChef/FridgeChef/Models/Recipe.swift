//
//  Recipe.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import Foundation
import FirebaseFirestore

struct Recipe: Identifiable, Codable {
    @DocumentID var id: String? // Firestore 的文件 ID
    var name: String // 食譜名稱
    var instructions: String // 食譜做法指導
    var cookingTime: Double // 烹飪時間（以分鐘為單位）
    var servings: String // 食譜份量
    var ingredientId: String? // 對應的食材 ID，可以是單一食材或一組食材的 ID

    init(id: String? = nil, name: String, instructions: String, cookingTime: Double, servings: String, ingredientId: String? = nil) {
        self.id = id
        self.name = name
        self.instructions = instructions
        self.cookingTime = cookingTime
        self.servings = servings
        self.ingredientId = ingredientId
    }
}
