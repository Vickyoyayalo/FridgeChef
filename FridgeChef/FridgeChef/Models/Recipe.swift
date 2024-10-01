//
//  Recipe.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/28.
//

import Foundation

// MARK: - Models

struct ParsedIngredient {
    var name: String
    var quantity: String
    var unit: String
}

struct ParsedRecipe {
    var title: String?
    var ingredients: [ParsedIngredient]
    var steps: [String]
    var link: String?
    var tips: String?
    var unparsedContent: String?
}

struct Recipe: Identifiable, Codable, Equatable {
    let id: Int
    let title: String
    let image: String?
    let servings: Int
    let readyInMinutes: Int
    let summary: String
    var isFavorite: Bool = false  // 本地屬性，默認為 false

    // CodingKeys 用來匹配 JSON key 和模型屬性
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case image
        case servings
        case readyInMinutes
        case summary
    }
}

struct RecipeSearchResponse: Codable {
    let results: [Recipe]
    let totalResults: Int
    
    enum CodingKeys: String, CodingKey {
        case results
        case totalResults
    }
}

struct RecipeDetails: Codable, Identifiable {
    let id: Int
    let title: String
    let image: String?
    var servings: Int
    let readyInMinutes: Int
    let sourceUrl: String?
    let summary: String?
    let cuisines: [String]
    let dishTypes: [String]
    let diets: [String]
    let instructions: String?
    var extendedIngredients: [DetailIngredient]
    let analyzedInstructions: [AnalyzedInstruction]?
    var isFavorite: Bool?  // 添加这个属性来标记是否被收藏
    
    mutating func adjustIngredientAmounts(forNewServings newServings: Int) {
        let ratio = Double(newServings) / Double(servings)
        extendedIngredients = extendedIngredients.map { ingredient in
            var newIngredient = ingredient
            newIngredient.amount *= ratio
            return newIngredient
        }
        servings = newServings
    }
}


struct AnalyzedInstruction: Codable, Identifiable {
    let id = UUID()
    let name: String
    let steps: [Step]
}

struct Step: Codable {
    let number: Int
    let step: String
    let ingredients: [IngredientItem]
    let equipment: [EquipmentItem]
}

struct EquipmentItem: Codable {
    let id: Int
    let name: String
    let localizedName: String
    let image: String
}


