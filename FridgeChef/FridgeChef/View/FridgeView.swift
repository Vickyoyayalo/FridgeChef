//
//  FridgeView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/19.
//

import SwiftUI

struct FridgeView: View {
    @EnvironmentObject var foodItemStore: FoodItemStore
    @State private var searchText = ""
    @State private var editingItem: FoodItem?
    @State private var showingProgressView = false
    @State private var progressMessage = ""
    @State private var showingMLIngredientView = false
  
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景漸變
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                
                GeometryReader { geometry in
                    VStack {
                        // 顯示背景圖片和文字
                        if filteredFoodItems.isEmpty {
                            VStack {
                                Image("SearchFood")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 350, height: 350)
                                    .cornerRadius(10)
                                    .shadow(radius: 8)

//                                Text("Happy with FOOD ~")
//                                    .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                                    .padding()
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .background(Color.clear)
                        }
                    }
                }
                
                VStack {
                    FridgeListView(
                        filteredFoodItems: filteredFoodItems,
                        moveToGrocery: moveToGrocery,
                        moveToFridge: moveToFridge,
                        moveToFreezer: moveToFreezer,
                        editingItem: $editingItem,
                        deleteItems: deleteItems
                    )
                }
            }
            .sheet(item: $editingItem) { selectedItem in
                let ingredient = convertToIngredient(item: selectedItem)
                
                MLIngredientView(onSave: { updatedIngredient in
                    handleSave(updatedIngredient)
                }, editingFoodItem: ingredient)
            }
            .navigationBarTitle("Fridge Storage 🥬", displayMode: .automatic)
            .navigationBarItems(leading: EditButton().bold(), trailing: addButton)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search food ingredient")
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
        let filtered = foodItemStore.foodItems.filter { $0.status == .fridge || $0.status == .freezer }
            .filter { item in
                searchText.isEmpty || item.name.lowercased().contains(searchText.lowercased())
            }
        print("FridgeStorageView - Filtered items count: \(filtered.count)")
        for item in filtered {
            print(" - \(item.name)")
        }
        return filtered
    }
    
    // 添加按鈕
    var addButton: some View {
        Button(action: {
            // 創建一個新的空的 FoodItem 來觸發 sheet
            editingItem = FoodItem(
                id: UUID(),
                name: "",
                quantity: 1.00, // 默認值
                unit: "unit",
                status: .fridge, // 默認狀態
                daysRemaining: 5,
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
          if let editing = editingItem, let index = foodItemStore.foodItems.firstIndex(where: { $0.id == editing.id }) {
              // 更新操作
              let today = Calendar.current.startOfDay(for: Date())
              let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
              foodItemStore.foodItems[index].name = ingredient.name
              foodItemStore.foodItems[index].quantity = ingredient.quantity ?? 1.0
              foodItemStore.foodItems[index].status = Status(rawValue: ingredient.storageMethod) ?? .fridge
              foodItemStore.foodItems[index].daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0
              foodItemStore.foodItems[index].image = ingredient.image
          } else {
              // 添加新項，默認為 "Fridge" 或 "Freezer" 取決於用戶輸入
              let today = Calendar.current.startOfDay(for: Date())
              let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
              let status = ingredient.storageMethod.isEmpty ? Status.fridge : Status(rawValue: ingredient.storageMethod) ?? .fridge
              let daysRemaining = status == .fridge ?  1 : 1
              let newFoodItem = FoodItem(
                  id: ingredient.id,
                  name: ingredient.name,
                  quantity: ingredient.quantity ?? 1.00,
                  unit: ingredient.unit,
                  status: status,
                  daysRemaining: Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? daysRemaining,
                  image: ingredient.image
              )
              foodItemStore.foodItems.insert(newFoodItem, at: 0)
              
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
    
    // 將食材移動回 GroceryList
    func moveToGrocery(item: FoodItem) {
        if let index = foodItemStore.foodItems.firstIndex(where: { $0.id == item.id }) {
            // 更新狀態和 daysRemaining
            foodItemStore.foodItems[index].status = .toBuy
            // 設置新的過期日期，例如 7 天後
            let newExpirationDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: newExpirationDate).day ?? 1
            foodItemStore.foodItems[index].daysRemaining = daysRemaining
            
            // 顯示 ProgressView
            showingProgressView = true
            progressMessage = "Food moved to Grocery List!"
            // 隱藏 ProgressView after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showingProgressView = false
            }
            
            print("Moved \(item.name) to Grocery List with status: \(foodItemStore.foodItems[index].status.rawValue)")
        }
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
            // 設置新的過期日期，例如 Fridge 為 7 天，Freezer 為 30 天
            let newExpirationDate = Calendar.current.date(byAdding: .day, value: storageMethod == "Fridge" ? 1 : 1, to: Date()) ?? Date()
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: newExpirationDate).day ?? 0
            foodItemStore.foodItems[index].daysRemaining = daysRemaining
            
            // 顯示 ProgressView
            showingProgressView = true
            progressMessage = "Food added to \(storageMethod)!"
            // 隱藏 ProgressView after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showingProgressView = false
            }
            
            print("Moved \(item.name) to \(storageMethod) with status: \(foodItemStore.foodItems[index].status.rawValue)")
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
            expirationDate: Date().addingTimeInterval(Double(item.daysRemaining * 24 * 60 * 60)),
            storageMethod: item.status.rawValue,
            imageBase64: base64Image
        )
    }
}

// MARK: - Subviews
struct FridgeListView: View {
    var filteredFoodItems: [FoodItem]
    var moveToGrocery: (FoodItem) -> Void
    var moveToFridge: (FoodItem) -> Void
    var moveToFreezer: (FoodItem) -> Void
    @Binding var editingItem: FoodItem?
    var deleteItems: (IndexSet) -> Void
    
    var body: some View {
        List {
            // Fridge Section
            if !filteredFoodItems.filter { $0.status == .fridge }.isEmpty {
                Section(header:
                            HStack {
                                Image(uiImage: UIImage(named: "fridge") ?? UIImage(systemName: "refrigerator.fill")!)
                                    .resizable()
                                    .frame(width: 24, height: 24) // 調整圖片大小
                                Text("Fridge")
                                    .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange)) 
                            }
                ) {
                    ForEach(filteredFoodItems.filter { $0.status == .fridge }) { item in
                        FoodItemRow(
                            item: item,
                            moveToGrocery: moveToGrocery,
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
            }

            // Freezer Section
            if !filteredFoodItems.filter { $0.status == .freezer }.isEmpty {
                Section(header:
                            HStack {
                                Image(uiImage: UIImage(named: "freezer") ?? UIImage(systemName: "snowflake")!)
                                    .resizable()
                                    .frame(width: 24, height: 24) // 調整圖片大小
                                Text("Freezer")
                                    .foregroundColor(.blue)
                            }
                ) {
                    ForEach(filteredFoodItems.filter { $0.status == .freezer }) { item in
                        FoodItemRow(
                            item: item,
                            moveToGrocery: moveToGrocery,
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
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Preview

struct FridgeView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleFoodItem = FoodItem(
            id: UUID(),
            name: "Apple",
            quantity: 3,
            unit: "個",
            status: .fridge,
            daysRemaining: 5,
            image: UIImage(systemName: "applelogo")
        )
        let store = FoodItemStore()
        store.foodItems = [sampleFoodItem]
        
        return FridgeView()
            .environmentObject(store)
    }
}
