//
//  FoodItem.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import Foundation
import SwiftUI

// 食材存儲類
class FoodItemStore: ObservableObject {
    @Published var foodItems: [FoodItem] = []
}

// 食材結構
struct FoodItem: Identifiable, Equatable {
    var id = UUID()
    var name: String
    var quantity: Double
    var unit: String
    var status: Status
    var daysRemaining: Int
    var expirationDate: Date?
    var image: UIImage?
}

// 狀態枚舉
enum Status: String {
    case toBuy = "toBuy"
    case fridge = "Fridge"
    case freezer = "Freezer"
}

// FoodItem.swift

extension FoodItem {
    var daysRemainingText: String {
        switch status {
        case .toBuy:
            if let expirationDate = expirationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                let dateString = formatter.string(from: expirationDate)
                return "To Buy by \(dateString)"
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                let today = Date()
                let dateString = formatter.string(from: today)
                return "To Buy \(dateString)"
            }
        case .fridge, .freezer:
            if daysRemaining > 2 {
                return "Can keep \(daysRemaining) days👨🏻‍🌾"
            } else if daysRemaining == 1 || daysRemaining == 2 {
                return "\(daysRemaining) day left👀"
            } else if daysRemaining == 0 {
                return "It's TODAY👵🏼"
            } else {
                return "Expired \(abs(daysRemaining)) days‼️"
            }
        }
    }

    var daysRemainingColor: Color {
        switch status {
        case .toBuy:
            return .blue // To Buy 狀態顯示藍色
        case .fridge:
            if daysRemaining > 2 {
                return .purple
            } else if daysRemaining == 1 || daysRemaining == 2 {
                return .green
            } else if daysRemaining == 0 {
                return .orange
            } else {
                return .red
            }
        case .freezer:
            if daysRemaining > 5 {
                return .gray
            } else if daysRemaining > 0 {
                return .pink
            } else {
                return .red
            }
        }
    }

    var daysRemainingFontWeight: Font.Weight {
        switch status {
        case .toBuy:
            return .bold
        case .fridge, .freezer:
            return daysRemaining < 0 ? .bold : .regular
        }
    }
}

// FoodItemRow.swift

import SwiftUI

struct FoodItemRow: View {
    var item: FoodItem
    var moveToGrocery: ((FoodItem) -> Void)?
    var moveToFridge: ((FoodItem) -> Void)?
    var moveToFreezer: ((FoodItem) -> Void)?
    var onTap: ((FoodItem) -> Void)? // 新增 onTap 閉包

    var body: some View {
        HStack {
            // 食材圖片
            if let image = item.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .cornerRadius(20)
            } else {
                Image("RecipeFood") // 默認圖片
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .cornerRadius(20)
            }
            
            // 食材詳細信息
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                Text("\(item.quantity, specifier: "%.2f") \(item.unit)")
                    .font(.subheadline)
                Text(item.daysRemainingText)
                    .font(.caption)
                    .foregroundColor(item.daysRemainingColor)
                    .fontWeight(item.daysRemainingFontWeight)
            }
            
            Spacer()
            
            // 按鈕區域
            HStack(spacing: 15) {
                // GroceryList 按鈕
                if let moveToGrocery = moveToGrocery {
                    Button(action: {
                        moveToGrocery(item)
                    }) {
                        Image(systemName: "cart.fill")
                            .foregroundColor(.green)
                    }
                }
                
                // Fridge 按鈕
                if let moveToFridge = moveToFridge {
                    Button(action: {
                        moveToFridge(item)
                    }) {
                        Image(systemName: "refrigerator.fill")
                            .foregroundColor(.orange)
                    }
                }
                
                // Freezer 按鈕
                if let moveToFreezer = moveToFreezer {
                    Button(action: {
                        moveToFreezer(item)
                    }) {
                        Image(systemName: "snowflake")
                            .foregroundColor(.blue)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle()) // 確保按鈕不會觸發父視圖的點擊事件
        }
        .contentShape(Rectangle()) // 確保整行可點擊
        .onTapGesture {
            onTap?(item) // 僅在非按鈕區域觸發
        }
    }
}



//struct FoodItemRow: View {
//    var item: FoodItem
//    var moveToGrocery: (FoodItem) -> Void
//    
//    var body: some View {
//        HStack {
//            if let image = item.image {
//                Image(uiImage: image)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 80, height: 80)
//                    .cornerRadius(20)
//            } else {
//                Image("RecipeFood")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 80, height: 80)
//                    .cornerRadius(20)
//            }
//            
//            VStack(alignment: .leading) {
//                Text("\(item.name)")
//                    .font(.headline)
//                Text("\(item.quantity) \(item.unit) - \(item.status.rawValue)")
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//                Text(item.daysRemainingText)
//                    .font(.caption)
//                    .foregroundColor(item.daysRemainingColor)
//                    .fontWeight(item.daysRemainingFontWeight)
//            }
//            Spacer()
//            Button(action: {
//                moveToGrocery(item)
//            }) {
//                Image(systemName: "cart.fill")
//                    .foregroundColor(.green)
//            }
//        }
//        .listRowBackground(Color.clear)
//        .listRowSeparator(.hidden)
//        .contentShape(Rectangle())
//    }
//}



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
