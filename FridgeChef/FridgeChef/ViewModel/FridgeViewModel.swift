//
//  FridgeViewModel.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import Foundation
import Combine

class FridgeViewModel: ObservableObject {
    @Published var ingredients: [Ingredient] = []
    
    func loadIngredients() {
        // 假設從本地讀取資料
        self.ingredients = [
//            Ingredient(name: "牛肉", quantity: 1, expirationDate: Date().addingTimeInterval(2 * 86400)),
//            Ingredient(name: "紅蘿蔔", quantity: 3, expirationDate: Date().addingTimeInterval(5 * 86400))
        ]
    }
    
    func getExpiringSoonIngredients() -> [Ingredient] {
        // 過濾即將過期的食材
        return ingredients.filter { $0.expirationDate <= Date().addingTimeInterval(2 * 86400) }
    }
}
