//
//  GroceryListView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//
import SwiftUI

struct GroceryListView: View {
    @EnvironmentObject var foodItemStore: FoodItemStore
    @State private var searchText = ""
    @State private var editingItem: FoodItem?
    @State private var showingProgressView = false
    @State private var progressMessage = ""
    @State private var showingMapView = false
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) { // 設定對齊方式
                // 背景漸變
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.4)
                .ignoresSafeArea() // 使用 ignoresSafeArea 替代 edgesIgnoringSafeArea
                
                // 主內容
                GroceryListContentView(
                    filteredFoodItems: filteredFoodItems,
                    moveToFridge: moveToFridge,
                    moveToFreezer: moveToFreezer,
                    editingItem: $editingItem,
                    deleteItems: deleteItems,
                    handleSave: handleSave
                )
                .sheet(item: $editingItem) { selectedItem in
                    let ingredient = convertToIngredient(item: selectedItem)
                    
                    MLIngredientView(onSave: { updatedIngredient in
                        handleSave(updatedIngredient)
                    }, editingFoodItem: ingredient)
                }
                
                // 漂浮按鈕
                FloatingMapButton(showingMapView: $showingMapView)
            }
            .navigationBarTitle("Grocery 🛒", displayMode: .automatic)
            .navigationBarItems(leading: EditButton().bold(), trailing: addButton)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search grocery items")
            .overlay(
                ProgressOverlay(showing: showingProgressView, message: progressMessage),
                alignment: .bottom
            )
        }
    }
        
    // 用來跟踪食材數量變化
    @State private var previousCount: Int = 0
    
    // 計算屬性，過濾食材
    var filteredFoodItems: [FoodItem] {
        let filtered = foodItemStore.foodItems.filter { $0.status == .toBuy }
            .filter { item in
                searchText.isEmpty || item.name.lowercased().contains(searchText.lowercased())
            }
        print("GroceryListView - Filtered items count: \(filtered.count)")
        for item in filtered {
            print(" - \(item.name): \(item.quantity)") // 調試輸出
        }
        return filtered
    }
    
    // 添加按鈕
    var addButton: some View {
        Button(action: {
            // 創建一個新的空的 FoodItem 來觸發 sheet，預設狀態為 .toBuy
            editingItem = FoodItem(
                id: UUID(),
                name: "",
                quantity: 1, // 默認值
                unit: "unit",
                status: .toBuy, // 默認狀態改為 .toBuy
                daysRemaining: 0,
                expirationDate: Date(),// 可選：設為 0 或其他適合的值
                image: nil
            )
        }) {
            Image(systemName: "plus")
                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                .bold()
        }
    }

    func deleteItems(at offsets: IndexSet) {
        foodItemStore.foodItems.remove(atOffsets: offsets)
    }
    
    // 保存食材
    func handleSave(_ ingredient: Ingredient) {
        print("Saving ingredient quantity: \(ingredient.quantity)") // 調試輸出
        if let editing = editingItem, let index = foodItemStore.foodItems.firstIndex(where: { $0.id == editing.id }) {
            // 更新操作
            let today = Calendar.current.startOfDay(for: Date())
            let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
            foodItemStore.foodItems[index].name = ingredient.name
            foodItemStore.foodItems[index].quantity = ingredient.quantity
            foodItemStore.foodItems[index].status = Status(rawValue: ingredient.storageMethod) ?? .fridge
            foodItemStore.foodItems[index].expirationDate = ingredient.expirationDate // 設置 expirationDate
            
            // 根據 status 計算 daysRemaining
            if foodItemStore.foodItems[index].status == .toBuy, let expirationDate = foodItemStore.foodItems[index].expirationDate {
                foodItemStore.foodItems[index].daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0
            } else {
                foodItemStore.foodItems[index].daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0
            }
            
            foodItemStore.foodItems[index].image = ingredient.imageBase64 != nil ? UIImage(data: Data(base64Encoded: ingredient.imageBase64!)!) : nil
            print("Updated FoodItem quantity: \(foodItemStore.foodItems[index].quantity)") // 調試輸出
        } else {
            // 添加新項目，默認為 "toBuy" 或其他狀態
            let today = Calendar.current.startOfDay(for: Date())
            let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
            let status = ingredient.storageMethod.isEmpty ? Status.toBuy : Status(rawValue: ingredient.storageMethod) ?? .toBuy
            let daysRemaining: Int
            switch status {
            case .fridge:
                daysRemaining = 5
            case .freezer:
                daysRemaining = 14
            case .toBuy:
                daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0 // 根據 expirationDate 計算
            }
            let newFoodItem = FoodItem(
                id: ingredient.id,
                name: ingredient.name,
                quantity: ingredient.quantity,
                unit: ingredient.unit,
                status: status,
                daysRemaining: daysRemaining, // 已經根據 status 計算
                expirationDate: ingredient.expirationDate, // 設置 expirationDate
                image: ingredient.imageBase64 != nil ? UIImage(data: Data(base64Encoded: ingredient.imageBase64!)!) : nil
            )
            foodItemStore.foodItems.insert(newFoodItem, at: 0)
            print("Added new FoodItem quantity: \(newFoodItem.quantity)") // 調試輸出
            
            // 顯示 ProgressView
            showingProgressView = true
            progressMessage = "Food added to \(newFoodItem.status.rawValue)!"
            // 隱藏 ProgressView after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showingProgressView = false
            }
        }
        
        // 重置 editingItem
        editingItem = nil
    }

    // 將食材移動到 Fridge 或 Freezer
    func moveToFridge(item: FoodItem) {
        moveToStorage(item: item, storageMethod: "Fridge")
    }
    
    func moveToFreezer(item: FoodItem) {
        moveToStorage(item: item, storageMethod: "Freezer")
    }
    
    // 通用的移動函數
    func moveToStorage(item: FoodItem, storageMethod: String) {
        if let index = foodItemStore.foodItems.firstIndex(where: { $0.id == item.id }) {
            // 更新狀態和 daysRemaining
            foodItemStore.foodItems[index].status = Status(rawValue: storageMethod) ?? .fridge
            // 設置新的過期日期，例如 Fridge 為 5 天，Freezer 為 14 天
            let newExpirationDate = Calendar.current.date(byAdding: .day, value: storageMethod == "Fridge" ? 5 : 14, to: Date()) ?? Date()
            let daysRemaining = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: newExpirationDate).day ?? 0
            foodItemStore.foodItems[index].daysRemaining = daysRemaining
            foodItemStore.foodItems[index].expirationDate = newExpirationDate // 設置 expirationDate
            
            // 顯示 ProgressView
            showingProgressView = true
            progressMessage = "Food added to \(storageMethod)!"
            // 隱藏 ProgressView after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showingProgressView = false
            }
            
            print("Moved \(item.name) to \(storageMethod) Storage with status: \(foodItemStore.foodItems[index].status.rawValue)")
        }
    }
    
    // 將 FoodItem 轉換為 Ingredient
    func convertToIngredient(item: FoodItem) -> Ingredient {
        // 轉換 FoodItem 為 Ingredient
        let base64Image = item.image?.pngData()?.base64EncodedString()
        return Ingredient(
            id: item.id,
            name: item.name,
            quantity: item.quantity,
            amount: 1.0, // 假設
            unit: item.unit,
            expirationDate: item.expirationDate ?? Date(),
            storageMethod: item.status.rawValue,
            imageBase64: base64Image
        )
    }
}

// MARK: - Subviews

struct GroceryListContentView: View {
    var filteredFoodItems: [FoodItem]
    var moveToFridge: (FoodItem) -> Void
    var moveToFreezer: (FoodItem) -> Void
    @Binding var editingItem: FoodItem?
    var deleteItems: (IndexSet) -> Void
    var handleSave: (Ingredient) -> Void
    
    var body: some View {
        List {
            ForEach(filteredFoodItems) { item in
                FoodItemRow(
                    item: item,
                    moveToFridge: moveToFridge,
                    moveToFreezer: moveToFreezer,
                    onTap: { selectedItem in
                        editingItem = selectedItem
                    }
                )
            }
            .onDelete(perform: deleteItems)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Preview

struct GroceryListView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleFoodItem = FoodItem(
            id: UUID(),
            name: "Milk",
            quantity: 2.00,
            unit: "瓶",
            status: .toBuy,
            daysRemaining: 5,
            expirationDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
            image: UIImage(systemName: "cart.fill")
        )
        let store = FoodItemStore()
        store.foodItems = [sampleFoodItem]
        
        return GroceryListView()
            .environmentObject(store)
    }
}
