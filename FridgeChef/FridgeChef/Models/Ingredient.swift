//
//  Ingredient.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//
import Foundation
import SwiftUI

// 更新後的 Ingredient 結構
struct Ingredient: Codable, Identifiable {
    var id: UUID = UUID() // 自动生成ID
    var name: String
    var quantity: String
    var amount: Double    // 你在调用时缺少这个参数
    var unit: String      // 你在调用时缺少这个参数
    var expirationDate: Date
    var storageMethod: String
    var imageBase64: String?  // 假设我们使用Base64字符串来存储图片

    // 使用计算属性来处理图片的获取和设置
    var image: UIImage? {
        get {
            guard let base64 = imageBase64, let imageData = Data(base64Encoded: base64) else { return nil }
            return UIImage(data: imageData)
        }
        set {
            imageBase64 = newValue?.pngData()?.base64EncodedString()
        }
    }

    // 編碼和解碼 UIImage 需要自定義編碼/解碼邏輯
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
        self.quantity = "\(foodItem.quantity)"
        self.amount = Double(foodItem.quantity)  // 假设 quantity 和 amount 有关联
        self.unit = "个"  // 假设 foodItem 没有单位，使用默认值
        let today = Date()
        let calendar = Calendar.current
        
        if let expirationDate = calendar.date(byAdding: .day, value: foodItem.daysRemaining, to: today) {
            self.expirationDate = expirationDate
        } else {
            self.expirationDate = today
        }
        
        self.storageMethod = foodItem.status
        
        // 将 UIImage 转换为 Base64 字符串
        if let image = foodItem.image, let imageData = image.pngData() {
            self.imageBase64 = imageData.base64EncodedString()
        } else {
            self.imageBase64 = nil
        }
    }
}
