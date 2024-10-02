//
//  FoodItem.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import Foundation
import FirebaseFirestore
import SwiftUI
import Combine

class FoodItemStore: ObservableObject {
    @Published var foodItems: [FoodItem] = []
}

struct FoodItem: Identifiable {
    var id = UUID()
    var name: String
    var quantity: Int
    var unit: String 
    var status: String
    var daysRemaining: Int
    var image: UIImage?
}

//extension FoodItem {
//    var daysRemainingText: String {
//        if daysRemaining > 2 {
//            return "Can keep \(daysRemaining) days👨🏻‍🌾"
//        } else if daysRemaining == 1 || daysRemaining == 2 {
//            return "\(daysRemaining) days left👀"
//        } else if daysRemaining == 0 {
//            return "It's TODAY👵🏼"
//        } else {
//            return "Already Expired \(abs(daysRemaining)) 天‼️"
//        }
//    }
//
//    var daysRemainingColor: Color {
//        if daysRemaining > 2 {
//            return .gray  // 大於 2 天為灰色
//        } else if daysRemaining == 1 || daysRemaining == 2 {
//            return .green  // 1~2 天內為綠色
//        } else if daysRemaining == 0 {
//            return .orange  // 今天到期為橘色
//        } else {
//            return .red  // 已過期為紅色
//        }
//    }
//    
//    
//    var daysRemainingFontWeight: Font.Weight {
//        return daysRemaining < 0 ? .bold : .regular
//    }
//}
//

extension FoodItem {
    var daysRemainingText: String {
        switch status {
        case "冷藏":
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            let today = Date()
            let dateString = formatter.string(from: today)
            return "To Buy \(dateString)"
        case "Fridge":
            if daysRemaining > 2 {
                return "\(daysRemaining) days left👨🏻‍🌾"
            } else if daysRemaining == 1 || daysRemaining == 2 {
                return "\(daysRemaining) days left👀"
            } else if daysRemaining == 0 {
                return "It's TODAY👵🏼"
            } else {
                return "Already Expired \(abs(daysRemaining)) 天‼️"
            }
        default:
            return "Unknown Status"
        }
    }

    var daysRemainingColor: Color {
        switch status {
        case "冷藏":
            return .blue // 冷藏狀態顯示藍色
        case "Fridge":
            if daysRemaining > 2 {
                return .gray
            } else if daysRemaining == 1 || daysRemaining == 2 {
                return .green
            } else if daysRemaining == 0 {
                return .orange
            } else {
                return .red
            }
        default:
            return .black
        }
    }

    var daysRemainingFontWeight: Font.Weight {
        switch status {
        case "冷藏":
            return .bold // 冷藏狀態顯示加粗
        case "Fridge":
            return daysRemaining < 0 ? .bold : .regular
        default:
            return .regular
        }
    }
}
