//
//  Recipe.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import Foundation
import FirebaseFirestore

struct Recipe: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var instructions: String // 食譜做法的指導
    var cookingTime: Double // 烹飪時間
    var servings: String // 份數
    var category: [String] // 類別（如中式、西式）
    var ingredients: [String] // 食材的ID

    init(id: String? = nil, name: String, instructions: String, cookingTime: Double, servings: String, category: [String], ingredients: [String]) {
        self.id = id
        self.name = name
        self.instructions = instructions
        self.cookingTime = cookingTime
        self.servings = servings
        self.category = category
        self.ingredients = ingredients
    }
}

