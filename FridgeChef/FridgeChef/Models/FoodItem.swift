//
//  FoodItem.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import Foundation
import FirebaseFirestore
import SwiftUI

struct FoodItem: Identifiable {
    var id = UUID()
    var name: String
    var quantity: Int
    var status: String
    var daysRemaining: Int
    var image: UIImage?
}

extension FoodItem {
    var daysRemainingText: String {
        if daysRemaining > 2 {
            return "還可以放\(daysRemaining) 天"
        } else if daysRemaining >= 0 {
            return "再\(abs(daysRemaining))天過期👀"
        } else {
            return "過期\(abs(daysRemaining)) 天‼️"
        }
    }
    //TODO可以寫個今天到期的邏輯
    var daysRemainingColor: Color {
        if daysRemaining > 2 {
            return .gray  // 大于 2 天为黑色
        } else if daysRemaining >= 0 {
            return .green  // 小于等于 2 天为绿色
        } else {
            return .red    // 已过期为红色
        }
    }
    
    var daysRemainingFontWeight: Font.Weight {
        return daysRemaining < 0 ? .bold : .regular
    }
}


//struct GroceryItem: Identifiable, Codable {
//    @DocumentID var id: String? // Firestore 的文件 ID
//    var name: String
//    var isSuggested: Bool
//    var priority: Int
//
//    init(id: String? = nil, ingredientId: String, isPurchased: Bool, priority: Int) {
//        self.id = id
//        self.name = name
//        self.isSuggested = isSuggested
//        self.priority = priority
//    }
//}
