//
//  ParsedIngredient.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/11/2.
//

import Foundation

struct ParsedIngredient: Identifiable, Codable, CustomStringConvertible {
    var id = UUID()
    let name: String
    let quantity: Double
    let unit: String
    let expirationDate: Date
    
    var description: String {
        return "ParsedIngredient(id: \(id), name: \"\(name)\", quantity: \(quantity), unit: \"\(unit)\", expirationDate: \(expirationDate))"
    }
}

