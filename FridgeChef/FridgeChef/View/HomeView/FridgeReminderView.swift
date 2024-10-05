//
//  FreshRecipesView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/05.
//
import SwiftUI

struct FridgeReminderView: View {
    @EnvironmentObject var foodItemStore: FoodItemStore
    @Binding var editingItem: FoodItem?

    private var expiringItems: [FoodItem] {
        foodItemStore.foodItems.filter { $0.daysRemaining <= 3 && $0.daysRemaining >= 0 }
    }

    private var expiredItems: [FoodItem] {
        foodItemStore.foodItems.filter { $0.daysRemaining < 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // 預設紅色卡片
                    if expiringItems.isEmpty {
                        DefaultFridgeReminderCard(color: .blue.opacity(0.2), message: "No items will expire within 3 days.", textColor: .blue)
                            .frame(width: 180, height: 250)
                    }

                    // 預設藍色卡片
                    if expiredItems.isEmpty {
                        DefaultFridgeReminderCard(color: .red.opacity(0.2), message: "No items expired.", textColor: .red)
                            .frame(width: 180, height: 250)
                    }

                    // 顯示即將過期的食物
                    ForEach(expiringItems) { item in
                        // 移除 onTapGesture，直接使用 NavigationLink
                        NavigationLink(destination: FridgeView()) {
                            FridgeRecipeCard(foodItem: item, isExpired: false)
                                .frame(width: 180, height: 250)
                        }
                    }

                    // 顯示已過期的食物
                    ForEach(expiredItems) { item in
                        NavigationLink(destination: FridgeView()) {
                            FridgeRecipeCard(foodItem: item, isExpired: true)
                                .frame(width: 180, height: 250)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16) // 去除邊界
        }
        .padding(.horizontal, 0)
    }
}


// 預設顯示的紅色或藍色卡片，當用戶沒有即將過期或已過期的食品時
struct DefaultFridgeReminderCard: View {
    let color: Color
    let message: String
    let textColor: Color // 設置文本的顏色
    
    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 8) {
                // 圖片佔位符
                Image("RecipeFood")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .cornerRadius(10)
                    .clipped() // 確保圖片不溢出邊界
                
                // 提示信息，設置為相同的最大高度，避免卡片大小不一
                Text(message)
                    .fontWeight(.medium)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(textColor) // 根據情況設置顏色
                    .frame(maxWidth: .infinity, maxHeight: 40) // 設置固定高度以確保大小一致
                    .padding(.top, 8)
            }
            .padding()
            .background(color) // 使用傳遞進來的顏色
            .cornerRadius(20.0)
        }
        .frame(width: 180, height: 250) // 調整卡片寬度和高度
        .padding(.trailing, 10)
    }
}

struct FridgeRecipeCard: View {
    let foodItem: FoodItem
    let isExpired: Bool

    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 8) {
                // 食物圖片
                if let image = foodItem.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .cornerRadius(10)
                        .clipped()
                        .frame(maxWidth: .infinity)
                } else {
                    Image("RecipeFood")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .cornerRadius(10)
                        .clipped()
                        .frame(maxWidth: .infinity)
                }

                // 食物名稱，支持換行
                Text(foodItem.name)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                // 食物數量和單位
                Text("\(foodItem.quantity, specifier: "%.2f") \(foodItem.unit)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                // 剩餘天數或已過期天數
                if isExpired {
                    Text("Expired \(abs(foodItem.daysRemaining)) days ago‼️")
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                } else {
                    Text("⚠️ \(foodItem.daysRemaining) days remaining")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .background(isExpired ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
            .cornerRadius(20.0)
        }
        .frame(width: 180, height: 250)
        .padding(.trailing, 10)
    }
}
