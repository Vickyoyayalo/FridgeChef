//
//  ParsedRecipe.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/11/2.
//

import Foundation

struct ParsedRecipe: Codable, CustomStringConvertible {
    let title: String?
    let ingredients: [ParsedIngredient]
    let steps: [String]
    var link: String?
    let tips: String?
    let unparsedContent: String?
    //    let language: String
    
    var description: String {
        return """
        ParsedRecipe(
            title: \(title ?? "nil"),
            ingredients: \(ingredients),
            steps: \(steps),
            link: \(link ?? "nil"),
            tips: \(tips ?? "nil"),
            unparsedContent: \(unparsedContent ?? "nil")
        )
        """
    }
}
