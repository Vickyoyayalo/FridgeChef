//
//  Recipe.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/28.
//

import Foundation

// MARK: - Models

struct Recipe: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let title: String
    let image: String?
    let servings: Int
    let readyInMinutes: Int
    let summary: String
    var isFavorite: Bool = false
    let dishTypes: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case image
        case servings
        case readyInMinutes
        case summary
        case dishTypes
    }
    
    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
    var isFavorite: Bool = false  // 修改為非可選型別，默認為 false
    
    enum CodingKeys: String, CodingKey {
        case id, title, image, servings, readyInMinutes, sourceUrl, summary, cuisines, dishTypes, diets, instructions, extendedIngredients, analyzedInstructions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        servings = try container.decode(Int.self, forKey: .servings)
        readyInMinutes = try container.decode(Int.self, forKey: .readyInMinutes)
        sourceUrl = try container.decodeIfPresent(String.self, forKey: .sourceUrl)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        cuisines = try container.decode([String].self, forKey: .cuisines)
        dishTypes = try container.decode([String].self, forKey: .dishTypes)
        diets = try container.decode([String].self, forKey: .diets)
        instructions = try container.decodeIfPresent(String.self, forKey: .instructions)
        extendedIngredients = try container.decode([DetailIngredient].self, forKey: .extendedIngredients)
        analyzedInstructions = try container.decodeIfPresent([AnalyzedInstruction].self, forKey: .analyzedInstructions)
        isFavorite = false
    }
    
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
    var id: UUID? = UUID()
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

enum ActiveAlert: Identifiable {
    case error(ErrorMessage)
    case ingredient(String)
    case accumulation(ParsedIngredient)
    case regular(title: String, message: String)

    var id: String {
        switch self {
        case .error(let errorMessage):
            return errorMessage.id.uuidString
        case .ingredient(let message):
            return message
        case .accumulation(let ingredient):
            return ingredient.name
        case .regular(let title, let message):
            return title + message
        }
    }
}
