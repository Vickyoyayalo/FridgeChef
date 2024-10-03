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

struct Ingredient: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var quantity: Double
    var amount: Double
    var unit: String
    var expirationDate: Date
    var storageMethod: String
    var imageBase64: String?
    
    var image: UIImage? {
        get {
            guard let base64 = imageBase64, let imageData = Data(base64Encoded: base64) else { return nil }
            return UIImage(data: imageData)
        }
        set {
            imageBase64 = newValue?.pngData()?.base64EncodedString()
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, amount, unit, quantity, expirationDate, storageMethod, imageBase64
    }
}
struct IngredientItem: Codable {
    let id: Int
    let name: String
    let localizedName: String
    let image: String
}

// 擴展 Codable 編碼/解碼邏輯
extension Ingredient {
    init(from foodItem: FoodItem) {
        self.id = UUID()  // 直接生成一个新的 UUID
        self.name = foodItem.name
        self.quantity = foodItem.quantity
        self.amount = Double(foodItem.quantity)  // 假设 quantity 和 amount 有关联
        self.unit = "unit"  // 假设 foodItem 没有单位，使用默认值
        let today = Date()
        let calendar = Calendar.current
        
        if let expirationDate = calendar.date(byAdding: .day, value: foodItem.daysRemaining, to: today) {
            self.expirationDate = expirationDate
        } else {
            self.expirationDate = today
        }
        
        self.storageMethod = foodItem.status.rawValue
        
        // 将 UIImage 转换为 Base64 字符串
        if let image = foodItem.image, let imageData = image.pngData() {
            self.imageBase64 = imageData.base64EncodedString()
        } else {
            self.imageBase64 = nil
        }
    }
}
