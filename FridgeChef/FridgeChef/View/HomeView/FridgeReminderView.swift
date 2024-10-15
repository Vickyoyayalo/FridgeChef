//
//  FreshRecipesView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/05.
//
import SwiftUI
import SDWebImageSwiftUI

struct FridgeReminderView: View {
    @EnvironmentObject var foodItemStore: FoodItemStore
    @Binding var editingItem: FoodItem?
    @State private var selectedFoodItem: FoodItem? // 用於顯示的已選擇食物
    @State private var showingSheet = false // 用於控制 sheet 顯示

    private var expiringItems: [FoodItem] {
        foodItemStore.foodItems.filter { $0.status != .toBuy && $0.daysRemaining <= 3 && $0.daysRemaining >= 0 }
    }

    private var expiredItems: [FoodItem] {
        foodItemStore.foodItems.filter { $0.status != .toBuy && $0.daysRemaining < 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // 預設紅色卡片
                    if expiringItems.isEmpty {
                        DefaultFridgeReminderCard(color: .blue.opacity(0.2), message: "No items will expire within 3 days.", textColor: .blue)
                    }

                    // 預設藍色卡片
                    if expiredItems.isEmpty {
                        DefaultFridgeReminderCard(color: .red.opacity(0.2), message: "No items expired.", textColor: .red)
                    }

                    // 顯示即將過期的食物
                    ForEach(expiringItems) { item in
                        Button(action: {
                            selectedFoodItem = item
                            showingSheet = true
                        }) {
                            FridgeRecipeCard(foodItem: item, isExpired: false)
                        }
                    }

                    // 顯示已過期的食物
                    ForEach(expiredItems) { item in
                        Button(action: {
                            selectedFoodItem = item
                            showingSheet = true
                        }) {
                            FridgeRecipeCard(foodItem: item, isExpired: true)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16) // 去除邊界
        }
        .padding(.horizontal)

        // .sheet 根據選中的 FoodItem 顯示不同的內容
        .sheet(item: $selectedFoodItem) { foodItem in
            if foodItem.status == .toBuy {
                GroceryListView() // 導航到購物清單
            } else {
                FridgeView() // 導航到冰箱
            }
        }
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
                Image("FridgeUpdate")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .cornerRadius(10)
                    .clipped() // 確保圖片不溢出邊界
                    .shadow(radius: 5)
                // 提示信息，設置為相同的最大高度，避免卡片大小不一
                Text(message)
                    .fontWeight(.medium)
                    .font(.custom("ArialRoundedMTBold", size: 14))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .foregroundColor(textColor) // 根據情況設置顏色
                    .frame(maxWidth: .infinity, maxHeight: 40) // 設置固定高度以確保大小一致
                    .padding(.top, 8)
                
            }
            .padding()
            .background(color) // 使用傳遞進來的顏色
            .cornerRadius(20.0)
            .shadow(radius: 8)
        }
        .frame(width: 180, height: 250) // 調整卡片寬度和高度
//        .padding(.trailing, 10)
    }
}

struct FridgeRecipeCard: View {
    let foodItem: FoodItem
    let isExpired: Bool

    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 8) {
                // Food image
                if let imageURLString = foodItem.imageURL, let imageURL = URL(string: imageURLString) {
                    WebImage(url: imageURL)
                        .resizable()
                        .background(
                            Image("RecipeFood") // Placeholder
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                        )
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .opacity(0.8)
                        )
                        .transition(.opacity) // SwiftUI's native fade transition
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .cornerRadius(10)
                        .clipped()
                        .frame(maxWidth: .infinity) // Ensure that maxWidth is correctly applied
                } else {
                    Image("RecipeFood")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .cornerRadius(10)
                        .clipped()
                        .frame(maxWidth: .infinity)
                }

                // Food name
                Text(foodItem.name)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                // Food quantity and unit
                Text("\(foodItem.quantity, specifier: "%.2f") \(foodItem.unit)")
                    .font(.custom("ArialRoundedMTBold", size: 13))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                // Days remaining or expired days
                if isExpired {
                    Text("Expired \n\(abs(foodItem.daysRemaining)) days ago‼️")
                        .font(.custom("ArialRoundedMTBold", size: 13))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                } else if foodItem.daysRemaining == 0 {
                    Text("It's TODAY 🍳")
                        .font(.custom("ArialRoundedMTBold", size: 13))
                        .foregroundColor(.purple) // 用不同顏色顯示當天到期
                        .multilineTextAlignment(.center)
                        .fontWeight(.bold)
                } else {
                    Text("⚠️ \(foodItem.daysRemaining) days \nRemaining")
                        .font(.custom("ArialRoundedMTBold", size: 13))
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


struct FridgeReminderView_Preview: PreviewProvider {
    @State static var editingItem: FoodItem? = nil

    static var previews: some View {
        FridgeReminderView(editingItem: $editingItem)
            .environmentObject(FoodItemStore()) // 提供環境對象
    }
}

