//
//  FoodItem.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//
import Foundation
import FirebaseAuth
import FirebaseFirestore


class FoodItemStore: ObservableObject {
    @Published var foodItems: [FoodItem] = []
    private var listener: ListenerRegistration?

    init() {
        fetchFoodItems()
    }

    func fetchFoodItems() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user is currently logged in.")
            return
        }

        listener = FirestoreService().listenToFoodItems(forUser: currentUser.uid) { [weak self] result in
            switch result {
            case .success(let items):
                DispatchQueue.main.async {
                    self?.foodItems = items  // 正確設置
                    print("Fetched \(items.count) food items from Firebase.")
                }
            case .failure(let error):
                print("Failed to fetch food items: \(error.localizedDescription)")
            }
        }
    }

    deinit {
        listener?.remove()
    }
}


import SwiftUI
// 食材結構
struct FoodItem: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var quantity: Double
    var unit: String
    var status: Status
    var daysRemaining: Int
    var expirationDate: Date?
    var imageURL: String?  // Replace imageBase64 with imageURL
    
    var uiImage: UIImage? {
            get {
                guard let imageURL = imageURL else { return nil }
                if let url = URL(string: imageURL), let data = try? Data(contentsOf: url) {
                    return UIImage(data: data)
                }
                return nil
            }
        }
    
    enum CodingKeys: String, CodingKey {
        case id, name, quantity, unit, status, daysRemaining, expirationDate, imageURL
    }
}

// 狀態枚舉
enum Status: String, Codable {
    case toBuy = "toBuy"
    case fridge = "Fridge"
    case freezer = "Freezer"
}

extension FoodItem {
    // 根據剩餘天數顯示不同的提示文字
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
            if daysRemaining > 5 {
                return "Can keep \(daysRemaining) days👨🏻‍🌾"
            } else if daysRemaining > 0 {
                return "\(daysRemaining) day\(daysRemaining > 1 ? "s" : "") left👀"
            } else if daysRemaining == 0 {
                return "It's TODAY🌶️"
            } else {
                return "Expired \(abs(daysRemaining)) days‼️"
            }
        }
    }

    // 根據剩餘天數顯示不同的顏色，Fridge 和 Freezer 顏色統一，To Buy 狀態超過今天的日期變成紅色
    var daysRemainingColor: Color {
        switch status {
        case .toBuy:
            if let expirationDate = expirationDate {
                if expirationDate < Date() { // 如果 expirationDate 小於當前日期，表示已過期
                    return .red
                } else {
                    return .blue
                }
            } else {
                return .blue
            }
        case .fridge, .freezer:
            if daysRemaining > 5 {
                return .gray // 超過5天顯示灰色
            } else if daysRemaining > 2 {
                return .purple // 3-5天顯示紫色
            } else if daysRemaining > 0 {
                return .blue // 1-2天顯示藍色
            } else if daysRemaining == 0 {
                return .orange // 當天顯示橙色
            } else {
                return .red // 已過期顯示紅色
            }
        }
    }

    // 5天內加粗字體
    var daysRemainingFontWeight: Font.Weight {
        switch status {
        case .toBuy:
            return .bold // To Buy 狀態加粗
        case .fridge, .freezer:
            return daysRemaining <= 5 ? .bold : .regular // 5天內的食材加粗字體
        }
    }
}

import SDWebImageSwiftUI

struct FoodItemRow: View {
    var item: FoodItem
    var moveToGrocery: ((FoodItem) -> Void)?
    var moveToFridge: ((FoodItem) -> Void)?
    var moveToFreezer: ((FoodItem) -> Void)?
    var onTap: ((FoodItem) -> Void)? // onTap 閉包
    
    var body: some View {
        HStack {
            if let imageURLString = item.imageURL, let imageURL = URL(string: imageURLString) {
                WebImage(url: imageURL)
                    .onSuccess { image, data, cacheType in
                        // Success handler if needed
                    }
                    .resizable() // Add resizable directly
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .background(
                        Image("RecipeFood")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .opacity(0.3) // Add opacity for a background-like effect
                    )
                
            } else {
                Image("RecipeFood")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
            }
            // 食材詳細信息
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.custom("ArialRoundedMTBold", size: 16))
                Text("\(item.quantity, specifier: "%.2f") \(item.unit)")
                    .font(.custom("ArialRoundedMTBold", size: 14))
                    .foregroundColor(.gray)
                Text(item.daysRemainingText)
                    .font(.custom("ArialRoundedMTBold", size: 14))
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
