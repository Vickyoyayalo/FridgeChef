//
//  Quantity.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//

import Foundation

struct Quantity: Codable {
    var amount: String // 數量
    var unit: Double // 單位，例如 "kg"
    
    init(amount: String, unit: Double) {
        self.amount = amount
        self.unit = unit
    }
}

