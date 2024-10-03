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
              let daysRemaining = status == .fridge ?  5 : 14
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
            let newExpirationDate = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: newExpirationDate).day ?? 5
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
            let newExpirationDate = Calendar.current.date(byAdding: .day, value: storageMethod == "Fridge" ? 7 : 30, to: Date()) ?? Date()
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: newExpirationDate).day ?? 0
            foodItemStore.foodItems[index].daysRemaining = daysRemaining
            
            // 顯示 ProgressView
            showingProgressView = true
            progressMessage = "Food added to \(storageMethod)!"
            // 隱藏 ProgressView after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
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
            ForEach(filteredFoodItems) { item in
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

//Done Before fixing MLpart
//import SwiftUI
//
//struct FridgeView: View {
//    @EnvironmentObject var foodItemStore: FoodItemStore
//    @State private var searchText = ""
//    @State private var showingMLIngredientView = false
//    @State private var editingItem: FoodItem?
//    @State private var showingProgressView = false
//    @State private var progressMessage = ""
//    @State private var showingMapView = false
//    
//    var body: some View {
//        NavigationView {
//            ZStack {
//                // 背景漸變
//                LinearGradient(
//                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//                .opacity(0.4)
//                .edgesIgnoringSafeArea(.all)
//                
//                VStack {
//                    FridgeListView(
//                        filteredFoodItems: filteredFoodItems,
//                        moveToGrocery: moveToGrocery,
//                        moveToFridge: moveToFridge,
//                        moveToFreezer: moveToFreezer,
//                        editingItem: $editingItem,
//                        showingMLIngredientView: $showingMLIngredientView,
//                        deleteItems: deleteItems
//                    )
//                }
//                .sheet(isPresented: $showingMLIngredientView) {
//                    if let editingItem = editingItem {
//                        // 编辑模式
//                        let ingredient = convertToIngredient(item: editingItem)
//                        
//                        MLIngredientView(onSave: { updatedIngredient in
//                            handleSave(updatedIngredient)
//                        }, editingFoodItem: ingredient)
//                    } else {
//                        // 新增模式
//                        MLIngredientView(onSave: { newIngredient in
//                            handleSave(newIngredient)
//                        })
//                    }
//                }
//                
//                // 地圖按鈕
//                FloatingMapButton(showingMapView: $showingMapView)
//            }
//            .listStyle(PlainListStyle())
//            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search food ingredient")
//            .navigationBarTitle("Fridge Storage 🥬", displayMode: .automatic)
//            .navigationBarItems(leading: EditButton().bold(), trailing: addButton)
//            .overlay(
//                ProgressOverlay(showing: showingProgressView, message: progressMessage),
//                alignment: .bottom
//            )
//            .onAppear {
//                previousCount = foodItemStore.foodItems.filter { $0.status == .fridge || $0.status == .freezer }.count
//            }
//            .onChange(of: foodItemStore.foodItems) { newItems in
//                let currentCount = newItems.filter { $0.status == .fridge || $0.status == .freezer }.count
//                if currentCount > previousCount {
//                    showingProgressView = true
//                    progressMessage = "Food added to Fridge/Freezer!"
//                    previousCount = currentCount
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                        showingProgressView = false
//                    }
//                }
//            }
//        }
//    }
//    
//    // 用來跟踪食材數量變化
//    @State private var previousCount: Int = 0
//    
//    // 計算屬性，過濾食材
//    var filteredFoodItems: [FoodItem] {
//        foodItemStore.foodItems.filter { $0.status == .fridge || $0.status == .freezer }
//            .filter { item in
//                searchText.isEmpty || item.name.lowercased().contains(searchText.lowercased())
//            }
//    }
//    
//    // 添加按鈕
//    var addButton: some View {
//        Button(action: {
//            // 点击添加按钮时设置为新增模式
//            editingItem = nil
//            showingMLIngredientView = true
//        }) {
//            Image(systemName: "plus")
//                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                .bold()
//        }
//    }
//    
//    // 删除食材
//    func deleteItems(at offsets: IndexSet) {
//        foodItemStore.foodItems.remove(atOffsets: offsets)
//    }
//    
//    // 保存食材
//    func handleSave(_ ingredient: Ingredient) {
//        if let editing = editingItem, let index = foodItemStore.foodItems.firstIndex(where: { $0.id == editing.id }) {
//            // 更新操作
//            let today = Calendar.current.startOfDay(for: Date())
//            let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
//            foodItemStore.foodItems[index].name = ingredient.name
//            foodItemStore.foodItems[index].quantity = Int(ingredient.quantity ?? "1") ?? 1
//            foodItemStore.foodItems[index].status = Status(rawValue: ingredient.storageMethod) ?? .fridge
//            foodItemStore.foodItems[index].daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0
//            foodItemStore.foodItems[index].image = ingredient.image
//        } else {
//            // 添加新项，默认为 "Fridge" 或 "Freezer" 取決於用户输入
//            let today = Calendar.current.startOfDay(for: Date())
//            let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
//            let status = ingredient.storageMethod.isEmpty ? Status.fridge : Status(rawValue: ingredient.storageMethod) ?? .fridge
//            let daysRemaining = status == .fridge ? 7 : 30
//            let newFoodItem = FoodItem(
//                id: ingredient.id,
//                name: ingredient.name,
//                quantity: Int(ingredient.quantity ?? "1") ?? 1,
//                unit: ingredient.unit,
//                status: status,
//                daysRemaining: Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? daysRemaining,
//                image: ingredient.image
//            )
//            foodItemStore.foodItems.insert(newFoodItem, at: 0)
//            
//            // 顯示 ProgressView
//            showingProgressView = true
//            progressMessage = "Food added to \(newFoodItem.status.rawValue)!"
//            // 隱藏 ProgressView after delay
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                showingProgressView = false
//            }
//        }
//        
//        // 重置 editingItem
//        editingItem = nil
//    }
//    
//    // 將食材移動回 GroceryList
//    func moveToGrocery(item: FoodItem) {
//        if let index = foodItemStore.foodItems.firstIndex(where: { $0.id == item.id }) {
//            // 更新狀態和 daysRemaining
//            foodItemStore.foodItems[index].status = .toBuy
//            // 設置新的過期日期，例如 7 天後
//            let newExpirationDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
//            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: newExpirationDate).day ?? 7
//            foodItemStore.foodItems[index].daysRemaining = daysRemaining
//            
//            // 顯示 ProgressView
//            showingProgressView = true
//            progressMessage = "Food moved to Grocery List!"
//            // 隱藏 ProgressView after delay
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                showingProgressView = false
//            }
//            
//            print("Moved \(item.name) to Grocery List with status: \(foodItemStore.foodItems[index].status.rawValue)")
//        }
//    }
//    
//    // 將食材移動到 Fridge 或 Freezer
//    func moveToFridge(item: FoodItem) {
//        moveToStorage(item: item, storageMethod: "Fridge")
//    }
//    
//    func moveToFreezer(item: FoodItem) {
//        moveToStorage(item: item, storageMethod: "Freezer")
//    }
//    
//    // 通用的移動函數
//    func moveToStorage(item: FoodItem, storageMethod: String) {
//        if let index = foodItemStore.foodItems.firstIndex(where: { $0.id == item.id }) {
//            // 更新狀態和 daysRemaining
//            foodItemStore.foodItems[index].status = Status(rawValue: storageMethod) ?? .fridge
//            // 設置新的過期日期，例如 Fridge 為 7 天，Freezer 為 30 天
//            let newExpirationDate = Calendar.current.date(byAdding: .day, value: storageMethod == "Fridge" ? 7 : 30, to: Date()) ?? Date()
//            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: newExpirationDate).day ?? 0
//            foodItemStore.foodItems[index].daysRemaining = daysRemaining
//            
//            // 顯示 ProgressView
//            showingProgressView = true
//            progressMessage = "Food added to \(storageMethod)!"
//            // 隱藏 ProgressView after delay
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                showingProgressView = false
//            }
//            
//            print("Moved \(item.name) to \(storageMethod) with status: \(foodItemStore.foodItems[index].status.rawValue)")
//        }
//    }
//    
//    // 將 FoodItem 轉換為 Ingredient
//    func convertToIngredient(item: FoodItem) -> Ingredient {
//        // 轉換 FoodItem 為 Ingredient
//        let base64Image = item.image?.pngData()?.base64EncodedString()
//        return Ingredient(
//            id: item.id,
//            name: item.name,
//            quantity: "\(item.quantity)",
//            amount: 1.0, // 假設
//            unit: item.unit,
//            expirationDate: Date().addingTimeInterval(Double(item.daysRemaining * 24 * 60 * 60)),
//            storageMethod: item.status.rawValue,
//            imageBase64: base64Image
//        )
//    }
//}
//
//// MARK: - Subviews
//
//struct FridgeListView: View {
//    var filteredFoodItems: [FoodItem]
//    var moveToGrocery: (FoodItem) -> Void
//    var moveToFridge: (FoodItem) -> Void
//    var moveToFreezer: (FoodItem) -> Void
//    @Binding var editingItem: FoodItem?
//    @Binding var showingMLIngredientView: Bool
//    var deleteItems: (IndexSet) -> Void
//    
//    var body: some View {
//        List {
//            ForEach(filteredFoodItems) { item in
//                FoodItemRow(
//                    item: item,
//                    moveToGrocery: moveToGrocery,
//                    moveToFridge: moveToFridge,
//                    moveToFreezer: moveToFreezer,
//                    onTap: { selectedItem in
//                        editingItem = selectedItem
//                        showingMLIngredientView = true
//                    }
//                )
//            }
//            .onDelete(perform: deleteItems)
//            .listRowBackground(Color.clear)
//            .listRowSeparator(.hidden)
//        }
//    }
//}
//
//// MARK: - Preview
//
//struct FridgeView_Previews: PreviewProvider {
//    static var previews: some View {
//        let sampleFoodItem = FoodItem(
//            id: UUID(),
//            name: "Apple",
//            quantity: 3,
//            unit: "個",
//            status: .fridge,
//            daysRemaining: 5,
//            image: UIImage(systemName: "applelogo")
//        )
//        let store = FoodItemStore()
//        store.foodItems = [sampleFoodItem]
//        
//        return FridgeView()
//            .environmentObject(store)
//    }
//}





////MARK:GOOD
//import SwiftUI
//
//struct FridgeView: View {
//    @EnvironmentObject var foodItemStore: FoodItemStore
//    @State private var searchText = ""
//    @State private var isEditing = false
//    @State private var showingMLIngredientView = false
//    @State private var editingItem: FoodItem?
//    //    @State var foodItems: [FoodItem] = []
//    
//    var body: some View {
//        NavigationView {
//            ZStack {
//                LinearGradient(
//                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//                .opacity(0.4)
//                .edgesIgnoringSafeArea(.all)
//                VStack {
//                    List {
    //                        ForEach(foodItemStore.foodItems.filter { $0.status.rawValue == "Fridge" && ($0.name.lowercased().contains(searchText.lowercased()) || searchText.isEmpty) }) { item in
//                            HStack {
//                                if let image = item.image {
//                                    Image(uiImage: image)
//                                        .resizable()
//                                        .scaledToFit()
//                                        .frame(width: 80, height: 80)
//                                        .cornerRadius(20)
//                                } else {
//                                    Image("RecipeFood")  // 顯示默認圖片
//                                        .resizable()
//                                        .scaledToFit()
//                                        .frame(width: 80, height: 80)
//                                        .cornerRadius(20)
//                                }
//                                
//                                VStack(alignment: .leading) {
//                                    Text("\(item.name)")
//                                    Text("\(item.quantity) - \(item.status)")
//                                        .font(.caption)
//                                        .foregroundColor(.gray)
//                                }
//                                Spacer()
//                                Text(item.daysRemainingText)
//                                    .foregroundColor(item.daysRemainingColor)
//                                    .fontWeight(item.daysRemainingFontWeight)
//                            }
//                            .listRowBackground(Color.clear)
//                            .listRowSeparator(.hidden)
//                            .contentShape(Rectangle())  // 讓整個區域可點擊
//                            .onTapGesture {
//                                // 當點擊某個項目時，打開編輯視圖
//                                editingItem = item
//                                showingMLIngredientView = true
//                            }
//                        }
//                        .onDelete(perform: deleteItems) // 添加删除功能
//                    }
//                    .background(Color.clear)
//                    .listStyle(PlainListStyle())
//                }
//                .sheet(isPresented: $showingMLIngredientView) {
//                    if let editingItem = editingItem {
//                        // 编辑模式
//                        // 假设默认量和单位
//                        let defaultAmount = 1.0  // 示例默认值
//                        let defaultUnit = "unit"  // 示例默认单位
//                        
//                        // 转换UIImage为Base64字符串
//                        let base64Image = editingItem.image?.pngData()?.base64EncodedString()
//                        
//                        let ingredient = Ingredient(
//                            name: editingItem.name,
//                            quantity: "\(editingItem.quantity)",
//                            amount: defaultAmount,
//                            unit: defaultUnit,
//                            expirationDate: Date().addingTimeInterval(Double(editingItem.daysRemaining * 24 * 60 * 60)),
    //                            storageMethod: editingItem.status.rawValue,
//                            imageBase64: base64Image
//                        )
//                        
//                        MLIngredientView(onSave: { updatedIngredient in
//                            handleSave(updatedIngredient)
//                        }, editingFoodItem: ingredient)
//                    } else {
//                        // 新增模式
//                        MLIngredientView(onSave: { newIngredient in
//                            handleSave(newIngredient)
//                        })
//                    }
//                }
//                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search food ingredient")
//                .navigationBarTitle("Storage 🥬 ", displayMode: .automatic)
//                .navigationBarItems(leading: EditButton().bold(), trailing: addButton)
//            }
//        }
//    }
//    
//    var addButton: some View {
//        Button(action: {
//            // 点击添加按钮时设置为新增模式
//            editingItem = nil
//            showingMLIngredientView = true
//        }) {
//            Image(systemName: "plus").foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                .bold()
//        }
//    }
//    
//    func deleteItems(at offsets: IndexSet) {
//        foodItemStore.foodItems.remove(atOffsets: offsets)
//    }
//    
//    func handleSave(_ ingredient: Ingredient) {
//        if let editing = editingItem, let index = foodItemStore.foodItems.firstIndex(where: { $0.id == editing.id }) {
//            // 更新操作
//            let today = Calendar.current.startOfDay(for: Date())
//            let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
//            foodItemStore.foodItems[index].name = ingredient.name
//            foodItemStore.foodItems[index].quantity = Int(ingredient.quantity) ?? 1
    //            Status(rawValue: foodItemStore.foodItems[index].status = ingredient.storageMethod) ?? <#default value#>
//            foodItemStore.foodItems[index].daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0
//            foodItemStore.foodItems[index].image = ingredient.image
//        } else {
//            // 新增操作
//            let today = Calendar.current.startOfDay(for: Date())
//            let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
//            let newFoodItem = FoodItem(
//                name: ingredient.name,
//                quantity: Int(ingredient.quantity) ?? 1,
//                unit: ingredient.unit,
    //                status: Status(rawValue: ingredient.storageMethod) ?? <#default value#>,
//                daysRemaining: Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0,
//                image: ingredient.image
//            )
//            foodItemStore.foodItems.insert(newFoodItem, at: 0)
//        }
//        // 重置 editingItem
//        editingItem = nil
//    }
//}
//
//struct FridgeView_Previews: PreviewProvider {
//    static var previews: some View {
//        FridgeView()
//            .environmentObject(FoodItemStore()) // 確保環境對象被傳遞
//    }
//}
//
////MARK:GOOD
//import SwiftUI
//
//struct FridgeView: View {
//    @State private var searchText = ""
//    @State private var isEditing = false // 控制刪除模式的狀態
//    @State private var showingMLIngredientView = false
//    @State private var editingItem: FoodItem?
//    @State var foodItems: [FoodItem] = []
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                List {
//                    ForEach(foodItems.filter { $0.name.lowercased().contains(searchText.lowercased()) || searchText.isEmpty }) { item in
//                        HStack {
//                            if let image = item.image {
//                                Image(uiImage: image)
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(width: 60, height: 60)
//                                    .cornerRadius(10)
//                            } else {
//                                Image("newphoto")  // 显示默认图片
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(width: 60, height: 60)
//                                    .cornerRadius(10)
//                            }
//
//                            VStack(alignment: .leading) {
//                                Text("\(item.name)")
//                                Text("\(item.quantity) - \(item.status)")
//                                    .font(.caption)
//                                    .foregroundColor(.gray)
//                            }
//                            Spacer()
//                            Text(item.daysRemainingText)
//                                .foregroundColor(item.daysRemainingColor)
//                                .fontWeight(item.daysRemainingFontWeight)
//                        }
//                        .contentShape(Rectangle())  // 讓整個區域可點擊
//                        .onTapGesture {
//                            // 當點擊某個項目時，打開編輯視圖
//                            editingItem = item
//                            showingMLIngredientView = true
//                        }
//                    }
//                    .onDelete(perform: deleteItems) // 添加删除功能
//                }
//            }
//            .sheet(isPresented: $showingMLIngredientView) {
//                if let editingItem = editingItem {
//                    MLIngredientView(onSave: { updatedIngredient in
//                        if let index = foodItems.firstIndex(where: { $0.id == editingItem.id }) {
//                            let today = Calendar.current.startOfDay(for: Date())
//                            let expirationDate = Calendar.current.startOfDay(for: updatedIngredient.expirationDate)
//                            foodItems[index].name = updatedIngredient.name
//                            foodItems[index].quantity = Int(updatedIngredient.quantity) ?? 1
//                            foodItems[index].status = updatedIngredient.storageMethod
//                            foodItems[index].daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0
//                            foodItems[index].image = updatedIngredient.image
//                        }
//                    }, editingFoodItem: Ingredient(
//                        name: editingItem.name,
//                        quantity: "\(editingItem.quantity)",
//                        expirationDate: Date().addingTimeInterval(Double(editingItem.daysRemaining * 24 * 60 * 60)),
//                        storageMethod: editingItem.status,
//                        image: editingItem.image
//                    ))
//                } else {
//                    // 新增模式
//                    MLIngredientView(onSave: { newIngredient in
//                        let today = Calendar.current.startOfDay(for: Date())
//                        let expirationDate = Calendar.current.startOfDay(for: newIngredient.expirationDate)
//                        let newFoodItem = FoodItem(
//                            name: newIngredient.name,
//                            quantity: Int(newIngredient.quantity) ?? 1,
//                            status: newIngredient.storageMethod,
//                            daysRemaining: Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0,
//                            image: newIngredient.image
//                        )
//                        foodItems.insert(newFoodItem, at: 0)
//                    })
//                }
//            }
//            .listStyle(PlainListStyle()) // 使用纯样式列表以减少间隙
//            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search food ingredient")
//            .navigationBarTitle("Storage", displayMode: .automatic)
//            .navigationBarItems(leading: EditButton(), trailing: addButton)
//            .sheet(isPresented: $showingMLIngredientView) {
//                MLIngredientView()
//            }
//        }
//    }
//    var addButton: some View {
//        Button(action: { showingMLIngredientView = true }) {
//            Image(systemName: "plus").foregroundColor(.orange)
//        }
//    }
//
//    func deleteItems(at offsets: IndexSet) {
//        foodItems.remove(atOffsets: offsets)
//    }
//
//}
//
//struct FridgeView_Previews: PreviewProvider {
//    static var previews: some View {
//        FridgeView()
//    }
//}

//MARK: MVVM架構可以修改的版本
//import SwiftUI
//
//struct FoodItem: Identifiable {
//    var id = UUID()
//    var name: String
//    var quantity: Int
//    var status: String
//    var daysRemaining: Int
//    var image: UIImage?
//}
//import SwiftUI
//
//struct FridgeView: View {
//    @State private var searchText = ""
//    @State private var showingMLIngredientView = false
//    @State private var editingItem: FoodItem?
//    @State var foodItems: [FoodItem] = []
//
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                List {
//                    ForEach(foodItems.filter { searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased()) }) { item in
//                        HStack {
//                            itemImageView(for: item.image)
//
//                            VStack(alignment: .leading) {
//                                Text(item.name)
//                                Text("\(item.quantity) - \(item.status)")
//                                    .font(.caption)
//                                    .foregroundColor(.gray)
//                            }
//                            Spacer()
//                            Text(item.daysRemainingText)
//                                .foregroundColor(item.daysRemainingColor)
//                                .fontWeight(item.daysRemainingFontWeight)
//                        }
//                        .contentShape(Rectangle())
//                        .onTapGesture {
//                            editingItem = item
//                            showingMLIngredientView = true
//                        }
//                    }
//                    .onDelete(perform: deleteItems)
//                }
//            }
//            .searchable(text: $searchText, prompt: "Search food ingredient")
//            .navigationBarTitle("Storage")
//            .navigationBarItems(leading: EditButton(), trailing: addButton)
//        }
//        .sheet(isPresented: $showingMLIngredientView) {
//            // Ensure that the view model creation and view initialization are clear and unambiguous.
//            Group {
//                if let editingItem = editingItem {
//                    let viewModel = MLIngredientViewModel()
////                    viewModel.setup(with: Ingredient(from: editingItem))
//                    MLIngredientView(viewModel: viewModel)  // Make sure MLIngredientView accepts a viewModel and is a View
//                } else {
//                    MLIngredientView(viewModel: MLIngredientViewModel())  // Same as above
//                }
//            }
//            .transition(.slide) // Optional: Adding a transition for better UI experience
//            .animation(.default, value: showingMLIngredientView) // Optional: Adding animation
//        }
//
//    }
//
//    private func itemImageView(for image: UIImage?) -> some View {
//        Image(uiImage: image ?? UIImage(named: "newphoto")!)
//            .resizable()
//            .scaledToFit()
//            .frame(width: 60, height: 60)
//            .cornerRadius(10)
//    }
//
//    private func convertToIngredient(_ item: FoodItem) -> Ingredient {
//        Ingredient(
//            name: item.name,
//            quantity: "\(item.quantity)",
//            expirationDate: Date().addingTimeInterval(Double(item.daysRemaining * 86400)),
//            storageMethod: item.status,
//            image: item.image
//        )
//    }
//
//    private func updateItem(_ ingredient: Ingredient, for item: FoodItem) {
//        if let index = foodItems.firstIndex(where: { $0.id == item.id }) {
//            let today = Calendar.current.startOfDay(for: Date())
//            let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
//            foodItems[index].name = ingredient.name
//            foodItems[index].quantity = Int(ingredient.quantity) ?? 1
//            foodItems[index].status = ingredient.storageMethod
//            foodItems[index].daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0
//            foodItems[index].image = ingredient.image
//        }
//    }
//
//    private func deleteItems(at offsets: IndexSet) {
//        foodItems.remove(atOffsets: offsets)
//    }
//
//    var addButton: some View {
//        Button(action: {
//            editingItem = nil  // This indicates a new item is being added
//            showingMLIngredientView = true
//        }) {
//            Image(systemName: "plus").foregroundColor(.orange)
//        }
//    }
//}
//
//extension FoodItem {
//    var daysRemainingText: String {
//        if daysRemaining > 2 {
//            return "還可以放\(daysRemaining) 天"
//        } else if daysRemaining >= 0 {
//            return "再\(abs(daysRemaining))天過期👀"
//        } else {
//            return "過期\(abs(daysRemaining)) 天‼️"
//        }
//    }
//    //TODO可以寫個今天到期的邏輯
//
//    var daysRemainingColor: Color {
//        if daysRemaining > 2 {
//            return .gray  // 大于 2 天为黑色
//        } else if daysRemaining >= 0 {
//            return .green  // 小于等于 2 天为绿色
//        } else {
//            return .red    // 已过期为红色
//        }
//    }
//
//    var daysRemainingFontWeight: Font.Weight {
//        return daysRemaining < 0 ? .bold : .regular
//    }
//}
//
//struct FridgeView_Previews: PreviewProvider {
//    static var previews: some View {
//        FridgeView()
//    }
//}
