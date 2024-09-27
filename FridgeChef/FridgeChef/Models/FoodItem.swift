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
            return "可以再放 \(daysRemaining) 天耶👨🏻‍🌾"
        } else if daysRemaining == 1 || daysRemaining == 2 {
            return "再 \(daysRemaining) 天過期👀"
        } else if daysRemaining == 0 {
            return "今天就要到期咯👵🏼"
        } else {
            return "過期 \(abs(daysRemaining)) 天‼️"
        }
    }

    var daysRemainingColor: Color {
        if daysRemaining > 2 {
            return .gray  // 大於 2 天為灰色
        } else if daysRemaining == 1 || daysRemaining == 2 {
            return .green  // 1~2 天內為綠色
        } else if daysRemaining == 0 {
            return .orange  // 今天到期為橘色
        } else {
            return .red  // 已過期為紅色
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
