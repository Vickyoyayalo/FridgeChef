//
//  GroceryListView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct GroceryListView: View {
    @EnvironmentObject var foodItemStore: FoodItemStore
    @State private var searchText = ""
    @State private var editingItem: FoodItem?
    @State private var showingProgressView = false
    @State private var progressMessage = ""
    @State private var showingMLIngredientView = false
    @State private var showingMapView = false
    @StateObject private var locationManager = LocationManager()
    let firestoreService = FirestoreService()
    
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
               
                GeometryReader { geometry in
                    VStack {
                        // 顯示背景圖片和文字
                        if filteredFoodItems.isEmpty {
                            VStack {
                                Image("Grocerymonster")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 350, height: 350)
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .background(Color.clear)
                        }
                    }
                }
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
                    
                    MLIngredientView(
                        onSave: { updatedIngredient in
                            handleSave(updatedIngredient)
                        },
                        editingFoodItem: ingredient
                    )
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
            .onAppear {
                listenToFoodItems() // 在視圖出現時啟動實時監聽
            }
        }
    }
    
    func listenToFoodItems() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user is currently logged in.")
            return
        }
        
        firestoreService.listenToFoodItems(forUser: currentUser.uid) { result in
            switch result {
            case .success(let items):
                DispatchQueue.main.async {
                    self.foodItemStore.foodItems = items
                    print("Real-time update: Fetched \(items.count) food items from Firebase.")
                }
            case .failure(let error):
                print("Failed to listen to food items: \(error.localizedDescription)")
            }
        }
    }
    
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
            // Present MLIngredientView without an editing item
            showingMLIngredientView = true
        }) {
            Image(systemName: "plus")
                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                .bold()
        }
        .sheet(isPresented: $showingMLIngredientView) {
            MLIngredientView(
                onSave: { newIngredient in
                    handleSave(newIngredient)
                }
            )
        }
    }

    func deleteItems(at offsets: IndexSet) {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user is currently logged in.")
            return
        }

        let itemsToDelete = offsets.map { filteredFoodItems[$0] }

        for item in itemsToDelete {
            // Delete from Firebase
            firestoreService.deleteFoodItem(forUser: currentUser.uid, foodItemId: item.id) { result in
                switch result {
                case .success():
                    print("Food item successfully deleted from Firebase.")
                case .failure(let error):
                    print("Failed to delete food item from Firebase: \(error.localizedDescription)")
                }
            }

            // Delete from local data source
            if let indexInFoodItems = foodItemStore.foodItems.firstIndex(where: { $0.id == item.id }) {
                foodItemStore.foodItems.remove(at: indexInFoodItems)
            }
        }
    }


    // 保存食材
    func handleSave(_ ingredient: Ingredient) {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user is currently logged in.")
            return
        }
        
        let foodItem = FoodItem(
            id: ingredient.id,
            name: ingredient.name,
            quantity: ingredient.quantity,
            unit: ingredient.unit,
            status: Status(rawValue: ingredient.storageMethod) ?? .fridge,
            daysRemaining: Calendar.current.dateComponents([.day], from: Date(), to: ingredient.expirationDate).day ?? 0,
            expirationDate: ingredient.expirationDate,
            imageURL: nil // We'll set this after uploading
        )
        
        if let index = foodItemStore.foodItems.firstIndex(where: { $0.id == ingredient.id }) {
            // Update existing item in local array
            foodItemStore.foodItems[index] = foodItem
            
            // Update in Firestore
            var updatedFields: [String: Any] = [
                "name": foodItem.name,
                "quantity": foodItem.quantity,
                "unit": foodItem.unit,
                "status": foodItem.status.rawValue,
                "daysRemaining": foodItem.daysRemaining,
                "expirationDate": Timestamp(date: foodItem.expirationDate ?? Date())
            ]
            
            // Handle image upload
            if let image = ingredient.image {
                let imagePath = "users/\(currentUser.uid)/foodItems/\(foodItem.id)/image.jpg"
                firestoreService.uploadImage(image, path: imagePath) { result in
                    switch result {
                    case .success(let url):
                        updatedFields["imageURL"] = url
                        // Update Firestore with imageURL
                        firestoreService.updateFoodItem(forUser: currentUser.uid, foodItemId: foodItem.id, updatedFields: updatedFields) { result in
                            // Handle result
                        }
                    case .failure(let error):
                        print("Failed to upload image: \(error.localizedDescription)")
                    }
                }
            } else {
                // Update Firestore without imageURL
                firestoreService.updateFoodItem(forUser: currentUser.uid, foodItemId: foodItem.id, updatedFields: updatedFields) { result in
                    // Handle result
                }
            }
            
        } else {
            // Add new item
            foodItemStore.foodItems.append(foodItem)
            
            // Save to Firestore
            firestoreService.addFoodItem(forUser: currentUser.uid, foodItem: foodItem, image: ingredient.image) { result in
                switch result {
                case .success():
                    print("Food item successfully added to Firebase.")
                case .failure(let error):
                    print("Failed to add food item to Firebase: \(error.localizedDescription)")
                }
            }
        }
        
        // Clear editingItem
        editingItem = nil
        
        // Ensure SwiftUI detects data update
        DispatchQueue.main.async {
            self.foodItemStore.objectWillChange.send()
        }
        
        // Show ProgressView
        showingProgressView = true
        progressMessage = "Food item saved!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            showingProgressView = false
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
            // Update status and expiration date
            foodItemStore.foodItems[index].status = Status(rawValue: storageMethod) ?? .fridge
            let newExpirationDate = Calendar.current.date(byAdding: .day, value: storageMethod == "Fridge" ? 5 : 14, to: Date()) ?? Date()
            foodItemStore.foodItems[index].expirationDate = newExpirationDate
            foodItemStore.foodItems[index].daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: newExpirationDate).day ?? 0

            // Update in Firebase
            guard let currentUser = Auth.auth().currentUser else {
                print("No user is currently logged in.")
                return
            }

            let updatedFields: [String: Any] = [
                "status": foodItemStore.foodItems[index].status.rawValue,
                "expirationDate": Timestamp(date: newExpirationDate),
                "daysRemaining": foodItemStore.foodItems[index].daysRemaining
            ]

            firestoreService.updateFoodItem(forUser: currentUser.uid, foodItemId: item.id, updatedFields: updatedFields) { result in
                switch result {
                case .success():
                    print("Food item successfully updated in Firebase.")
                case .failure(let error):
                    print("Failed to update food item in Firebase: \(error.localizedDescription)")
                }
            }

            // Notify SwiftUI of data change
            DispatchQueue.main.async {
                self.foodItemStore.objectWillChange.send()
            }

            // Show progress view
            showingProgressView = true
            progressMessage = "Food moved to \(storageMethod)!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showingProgressView = false
            }

            print("Moved \(item.name) to \(storageMethod) Storage with status: \(foodItemStore.foodItems[index].status.rawValue)")
        }
    }


    // 將 FoodItem 轉換為 Ingredient
    func convertToIngredient(item: FoodItem) -> Ingredient {
        // Fetch the image asynchronously if needed, but for now, you can set image to nil
        return Ingredient(
            id: item.id,
            name: item.name,
            quantity: item.quantity,
            amount: 1.0, // Adjust as appropriate
            unit: item.unit,
            expirationDate: item.expirationDate ?? Date(),
            storageMethod: item.status.rawValue,
            image: nil,
            imageURL: item.imageURL// You may need to fetch the image from item.imageURL if necessary
        )
    }

    // 將 Ingredient 轉換回 FoodItem（假設有此需求）
    func convertToFoodItem(ingredient: Ingredient) -> FoodItem {
        return FoodItem(
            id: ingredient.id, // 保持 id 一致
            name: ingredient.name,
            quantity: ingredient.quantity,
            unit: ingredient.unit,
            status: Status(rawValue: ingredient.storageMethod) ?? .toBuy,
            daysRemaining: Calendar.current.dateComponents([.day], from: Date(), to: ingredient.expirationDate).day ?? 0,
            expirationDate: ingredient.expirationDate
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
            .onDelete { offsets in
                deleteItems(offsets)
            }
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
            id: UUID().uuidString,
            name: "Milk",
            quantity: 2.00,
            unit: "瓶",
            status: .toBuy,
            daysRemaining: 5,
            expirationDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
            imageURL: nil
        )
        let store = FoodItemStore()
        store.foodItems = [sampleFoodItem]
        
        return GroceryListView()
            .environmentObject(store)
    }
}

//import SwiftUI
//
//struct GroceryListView: View {
//    @EnvironmentObject var foodItemStore: FoodItemStore
//    @State private var searchText = ""
//    @State private var editingItem: FoodItem?
//    @State private var showingProgressView = false
//    @State private var progressMessage = ""
//    @State private var showingMapView = false
//    @StateObject private var locationManager = LocationManager()
//
//    var body: some View {
//        NavigationView {
//            ZStack(alignment: .bottomTrailing) { // 設定對齊方式
//                // 背景漸變
//                LinearGradient(
//                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//                .opacity(0.4)
//                .ignoresSafeArea() // 使用 ignoresSafeArea 替代 edgesIgnoringSafeArea
//
//                GeometryReader { geometry in
//                    VStack {
//                        // 顯示背景圖片和文字
//                        if filteredFoodItems.isEmpty {
//                            VStack {
////                                Text("Buy some food!!!")
////                                    .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
////                                    .font(.custom("ArialRoundedMTBold", size: 40))
//                                Image("Grocerymonster")
//                                    .resizable()
//                                    .scaledToFill()
//                                    .frame(width: 350, height: 350)
//                            }
//                            .frame(width: geometry.size.width, height: geometry.size.height)
//                            .background(Color.clear)
//                        }
//                    }
//                }
//                // 主內容
//                GroceryListContentView(
//                    filteredFoodItems: filteredFoodItems,
//                    moveToFridge: moveToFridge,
//                    moveToFreezer: moveToFreezer,
//                    editingItem: $editingItem,
//                    deleteItems: deleteItems,
//                    handleSave: handleSave
//                )
//                .sheet(item: $editingItem) { selectedItem in
//                    let ingredient = convertToIngredient(item: selectedItem)
//
//                    MLIngredientView(onSave: { updatedIngredient in
//                        handleSave(updatedIngredient)
//                    }, editingFoodItem: ingredient)
//                }
//
//                // 漂浮按鈕
//                FloatingMapButton(showingMapView: $showingMapView)
//            }
//            .navigationBarTitle("Grocery 🛒", displayMode: .automatic)
//            .navigationBarItems(leading: EditButton().bold(), trailing: addButton)
//            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search grocery items")
//            .overlay(
//                ProgressOverlay(showing: showingProgressView, message: progressMessage),
//                alignment: .bottom
//            )
//        }
//    }
//
//    // 用來跟踪食材數量變化
//    @State private var previousCount: Int = 0
//
//    // 計算屬性，過濾食材
//    var filteredFoodItems: [FoodItem] {
//        let filtered = foodItemStore.foodItems.filter { $0.status == .toBuy }
//            .filter { item in
//                searchText.isEmpty || item.name.lowercased().contains(searchText.lowercased())
//            }
//        print("GroceryListView - Filtered items count: \(filtered.count)")
//        for item in filtered {
//            print(" - \(item.name): \(item.quantity)") // 調試輸出
//        }
//        return filtered
//    }
//
//    // 添加按鈕
//    var addButton: some View {
//        Button(action: {
//            // 創建一個新的空的 FoodItem 來觸發 sheet，預設狀態為 .toBuy
//            editingItem = FoodItem(
//                id: UUID(),
//                name: "",
//                quantity: 1, // 默認值
//                unit: "unit",
//                status: .toBuy, // 默認狀態改為 .toBuy
//                daysRemaining: 0,
//                expirationDate: Date(),// 可選：設為 0 或其他適合的值
//                image: nil
//            )
//        }) {
//            Image(systemName: "plus")
//                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                .bold()
//        }
//    }
//
//    func deleteItems(at offsets: IndexSet) {
//        foodItemStore.foodItems.remove(atOffsets: offsets)
//    }
//
//    // 保存食材
//    func handleSave(_ ingredient: Ingredient) {
//        print("Saving ingredient quantity: \(ingredient.quantity)") // 調試輸出
//        if let editing = editingItem, let index = foodItemStore.foodItems.firstIndex(where: { $0.id == editing.id }) {
//            // 更新操作
//            let today = Calendar.current.startOfDay(for: Date())
//            let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
//            foodItemStore.foodItems[index].name = ingredient.name
//            foodItemStore.foodItems[index].quantity = ingredient.quantity
//            foodItemStore.foodItems[index].status = Status(rawValue: ingredient.storageMethod) ?? .fridge
//            foodItemStore.foodItems[index].expirationDate = ingredient.expirationDate // 設置 expirationDate
//
//            // 根據 status 計算 daysRemaining
//            if foodItemStore.foodItems[index].status == .toBuy, let expirationDate = foodItemStore.foodItems[index].expirationDate {
//                foodItemStore.foodItems[index].daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0
//            } else {
//                foodItemStore.foodItems[index].daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0
//            }
//
//            foodItemStore.foodItems[index].image = ingredient.imageBase64 != nil ? UIImage(data: Data(base64Encoded: ingredient.imageBase64!)!) : nil
//            print("Updated FoodItem quantity: \(foodItemStore.foodItems[index].quantity)") // 調試輸出
//        } else {
//            // 添加新項目，默認為 "toBuy" 或其他狀態
//            let today = Calendar.current.startOfDay(for: Date())
//            let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
//            let status = ingredient.storageMethod.isEmpty ? Status.toBuy : Status(rawValue: ingredient.storageMethod) ?? .toBuy
//            let daysRemaining: Int
//            switch status {
//            case .fridge:
//                daysRemaining = 5
//            case .freezer:
//                daysRemaining = 14
//            case .toBuy:
//                daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0 // 根據 expirationDate 計算
//            }
//            let newFoodItem = FoodItem(
//                id: ingredient.id,
//                name: ingredient.name,
//                quantity: ingredient.quantity,
//                unit: ingredient.unit,
//                status: status,
//                daysRemaining: daysRemaining, // 已經根據 status 計算
//                expirationDate: ingredient.expirationDate, // 設置 expirationDate
//                image: ingredient.imageBase64 != nil ? UIImage(data: Data(base64Encoded: ingredient.imageBase64!)!) : nil
//            )
//            foodItemStore.foodItems.insert(newFoodItem, at: 0)
//            print("Added new FoodItem quantity: \(newFoodItem.quantity)") // 調試輸出
//
//            // 顯示 ProgressView
//            showingProgressView = true
//            progressMessage = "Food added to \(newFoodItem.status.rawValue)!"
//            // 隱藏 ProgressView after delay
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                showingProgressView = false
//            }
//        }
//
//        // 重置 editingItem
//        editingItem = nil
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
//            foodItemStore.foodItems[index].status = Status(rawValue: storageMethod) ?? .toBuy
//            // 設置新的過期日期，例如 Fridge 為 5 天，Freezer 為 14 天
//            let newExpirationDate = Calendar.current.date(byAdding: .day, value: storageMethod == "Fridge" ? 5 : 14, to: Date()) ?? Date()
//            let daysRemaining = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: newExpirationDate).day ?? 0
//            foodItemStore.foodItems[index].daysRemaining = daysRemaining
//            foodItemStore.foodItems[index].expirationDate = newExpirationDate // 設置 expirationDate
//
//            // 顯示 ProgressView
//            showingProgressView = true
//            progressMessage = "Food added to \(storageMethod)!"
//            // 隱藏 ProgressView after delay
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                showingProgressView = false
//            }
//
//            print("Moved \(item.name) to \(storageMethod) Storage with status: \(foodItemStore.foodItems[index].status.rawValue)")
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
//            quantity: item.quantity,
//            amount: 1.0, // 假設
//            unit: item.unit,
//            expirationDate: item.expirationDate ?? Date(),
//            storageMethod: item.status.rawValue,
//            imageBase64: base64Image
//        )
//    }
//}
//
//// MARK: - Subviews
//
//struct GroceryListContentView: View {
//    var filteredFoodItems: [FoodItem]
//    var moveToFridge: (FoodItem) -> Void
//    var moveToFreezer: (FoodItem) -> Void
//    @Binding var editingItem: FoodItem?
//    var deleteItems: (IndexSet) -> Void
//    var handleSave: (Ingredient) -> Void
//
//    var body: some View {
//        List {
//            ForEach(filteredFoodItems) { item in
//                FoodItemRow(
//                    item: item,
//                    moveToFridge: moveToFridge,
//                    moveToFreezer: moveToFreezer,
//                    onTap: { selectedItem in
//                        editingItem = selectedItem
//                    }
//                )
//            }
//            .onDelete(perform: deleteItems)
//            .listRowBackground(Color.clear)
//            .listRowSeparator(.hidden)
//        }
//        .listStyle(PlainListStyle())
//    }
//}
//
//// MARK: - Preview
//
//struct GroceryListView_Previews: PreviewProvider {
//    static var previews: some View {
//        let sampleFoodItem = FoodItem(
//            id: UUID(),
//            name: "Milk",
//            quantity: 2.00,
//            unit: "瓶",
//            status: .toBuy,
//            daysRemaining: 5,
//            expirationDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
//            image: UIImage(systemName: "cart.fill")
//        )
//        let store = FoodItemStore()
//        store.foodItems = [sampleFoodItem]
//
//        return GroceryListView()
//            .environmentObject(store)
//    }
//}
