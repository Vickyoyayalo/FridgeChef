//
//  Ingredient.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import Foundation
import SwiftUI

struct DetailIngredient: Codable, Identifiable {
    var id: Int
    var name: String
    var amount: Double
    var unit: String
}

struct Ingredient: Identifiable {
    var id: String
    var name: String
    var quantity: Double
    var amount: Double
    var unit: String
    var expirationDate: Date
    var storageMethod: String
    var image: UIImage?  // Store UIImage directly
    var imageURL: String?
}

extension Ingredient: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, quantity, amount, unit, expirationDate, storageMethod
    }
}

struct IngredientItem: Codable {
    let id: Int
    let name: String
    let localizedName: String
    let image: String
}

extension Ingredient {
    init(from foodItem: FoodItem) {
        self.id = foodItem.id
        self.name = foodItem.name
        self.quantity = foodItem.quantity
        self.amount = Double(foodItem.quantity)
        self.unit = "unit"
        let today = Date()
        let calendar = Calendar.current
        
        if let expirationDate = calendar.date(byAdding: .day, value: foodItem.daysRemaining, to: today) {
            self.expirationDate = expirationDate
        } else {
            self.expirationDate = today
        }
        self.storageMethod = foodItem.status.rawValue
        
    }
}
