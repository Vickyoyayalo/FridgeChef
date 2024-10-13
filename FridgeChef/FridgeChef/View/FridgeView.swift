//
//  FridgeView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/19.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FridgeView: View {
    @EnvironmentObject var foodItemStore: FoodItemStore
    @State private var searchText = ""
    @State private var editingItem: FoodItem?
    @State private var showingProgressView = false
    @State private var progressMessage = ""
    @State private var showingMLIngredientView = false
    let firestoreService = FirestoreService()
    
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
                        deleteItems: deleteItems  // Pass the function directly
                    )
                }
            }
            .sheet(item: $editingItem) { selectedItem in
                let ingredient = convertToIngredient(item: selectedItem)
                
                MLIngredientView(
                    onSave: { updatedIngredient in
                        handleSave(updatedIngredient)
                    },
                    editingFoodItem: ingredient
                )
            }
            
            .navigationBarTitle("Fridge Storage 🥬", displayMode: .automatic)
            .navigationBarItems(leading: EditButton().bold(), trailing: addButton)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search food ingredient")
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
        let filtered = foodItemStore.foodItems.filter { $0.status == .fridge || $0.status == .freezer }
            .filter { item in
                searchText.isEmpty || item.name.lowercased().contains(searchText.lowercased())
            }
        print("FridgeStorageView - Filtered items count: \(filtered.count)")
        for item in filtered {
            print(" - \(item.name): \(item.quantity)")
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
    
    func deleteItems(at offsets: IndexSet, from items: [FoodItem]) {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user is currently logged in.")
            return
        }
        
        let itemsToDelete = offsets.map { items[$0] }
        
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
                    case .success(let url):  // 這裡假設返回的是 String 類型的 URL
                        updatedFields["imageURL"] = url  // 直接將 String 保存到 imageURL
                        firestoreService.updateFoodItem(forUser: currentUser.uid, foodItemId: foodItem.id, updatedFields: updatedFields) { result in
                            // Handle result
                        }
                    case .failure(let error):
                        print("Failed to upload image: \(error.localizedDescription)")
                    }
                }
            } else {
                // 沒有圖片上傳，仍然需要更新其餘字段
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

    // 將食材移動回 GroceryList
    func moveToGrocery(item: FoodItem) {
        if let index = foodItemStore.foodItems.firstIndex(where: { $0.id == item.id }) {
            // Update status and daysRemaining
            foodItemStore.foodItems[index].status = .toBuy
            // Set new expiration date, e.g., 1 day later
            let newExpirationDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: newExpirationDate).day ?? 1
            foodItemStore.foodItems[index].daysRemaining = daysRemaining
            foodItemStore.foodItems[index].expirationDate = newExpirationDate

            // Update Firebase
            guard let currentUser = Auth.auth().currentUser else {
                print("No user is currently logged in.")
                return
            }

            let updatedFields: [String: Any] = [
                "status": foodItemStore.foodItems[index].status.rawValue,
                "daysRemaining": daysRemaining,
                "expirationDate": Timestamp(date: newExpirationDate)
            ]

            firestoreService.updateFoodItem(forUser: currentUser.uid, foodItemId: item.id, updatedFields: updatedFields) { result in
                switch result {
                case .success():
                    print("Food item successfully updated in Firebase.")
                case .failure(let error):
                    print("Failed to update food item in Firebase: \(error.localizedDescription)")
                }
            }

            // Show ProgressView
            showingProgressView = true
            progressMessage = "Food moved to Grocery List!"
            // Hide ProgressView after delay
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
            // 更新状态和剩余天数
            let newStatus = Status(rawValue: storageMethod) ?? .fridge
            foodItemStore.foodItems[index].status = newStatus
            let newExpirationDate = Calendar.current.date(byAdding: .day, value: storageMethod == "Fridge" ? 5 : 14, to: Date()) ?? Date()
            foodItemStore.foodItems[index].expirationDate = newExpirationDate
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: newExpirationDate).day ?? 0
            foodItemStore.foodItems[index].daysRemaining = daysRemaining

            // 更新 Firebase
            guard let currentUser = Auth.auth().currentUser else {
                print("No user is currently logged in.")
                return
            }

            let updatedFields: [String: Any] = [
                "status": newStatus.rawValue,
                "daysRemaining": daysRemaining,
                "expirationDate": Timestamp(date: newExpirationDate)
            ]

            firestoreService.updateFoodItem(forUser: currentUser.uid, foodItemId: item.id, updatedFields: updatedFields) { result in
                switch result {
                case .success():
                    print("Food item successfully updated in Firebase.")
                case .failure(let error):
                    print("Failed to update food item in Firebase: \(error.localizedDescription)")
                }
            }

            // 确保 SwiftUI 检测到数据更新
            DispatchQueue.main.async {
                self.foodItemStore.objectWillChange.send()
            }

            // 显示 ProgressView
            showingProgressView = true
            progressMessage = "Moved to \(storageMethod)!"
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
}
// MARK: - Subviews
struct FridgeListView: View {
    var filteredFoodItems: [FoodItem]
    var moveToGrocery: (FoodItem) -> Void
    var moveToFridge: (FoodItem) -> Void
    var moveToFreezer: (FoodItem) -> Void
    @Binding var editingItem: FoodItem?
    var deleteItems: (IndexSet, [FoodItem]) -> Void 
   
    var body: some View {
           List {
               // Fridge Section
               if !filteredFoodItems.filter { $0.status == .fridge }.isEmpty {
                   Section(header:  HStack {
                       Image(uiImage: UIImage(named: "fridge") ?? UIImage(systemName: "refrigerator.fill")!)
                           .resizable()
                           .frame(width: 24, height: 24) // 調整圖片大小
                       Text("Fridge")
                           .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                   }) {
                       let fridgeItems = filteredFoodItems.filter { $0.status == .fridge }
                       ForEach(fridgeItems) { item in
                           
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
                       .onDelete { offsets in
                           deleteItems(offsets, fridgeItems)
                       }
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
                           }) {
                       let freezerItems = filteredFoodItems.filter { $0.status == .freezer }
                       ForEach(freezerItems) { item in
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
                       .onDelete { offsets in
                           deleteItems(offsets, freezerItems)
                       }
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
            id: UUID().uuidString,
            name: "Apple",
            quantity: 3,
            unit: "個",
            status: .fridge,
            daysRemaining: 5,
            expirationDate: Date(),
            imageURL: nil
        )
        let store = FoodItemStore()
        store.foodItems = [sampleFoodItem]
        
        return FridgeView()
            .environmentObject(store)
    }
}
//    var body: some View {
//        List {
//            // Fridge Section
//            if !filteredFoodItems.filter { $0.status == .fridge }.isEmpty {
//                Section(header:
//                            HStack {
//                                Image(uiImage: UIImage(named: "fridge") ?? UIImage(systemName: "refrigerator.fill")!)
//                                    .resizable()
//                                    .frame(width: 24, height: 24) // 調整圖片大小
//                                Text("Fridge")
//                                    .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange)) 
//                            }
//                ) {
//                    ForEach(filteredFoodItems.filter { $0.status == .fridge }) { item in
//                        FoodItemRow(
//                            item: item,
//                            moveToGrocery: moveToGrocery,
//                            moveToFridge: moveToFridge,
//                            moveToFreezer: moveToFreezer,
//                            onTap: { selectedItem in
//                                editingItem = selectedItem
//                            }
//                        )
//                    }
//                    .onDelete { offsets in
//                        deleteItems(offsets, filteredFoodItems.filter { $0.status == .fridge })
//                    }
//                    .listRowBackground(Color.clear)
//                    .listRowSeparator(.hidden)
//                }
//            }
//
//            // Freezer Section
//            if !filteredFoodItems.filter { $0.status == .freezer }.isEmpty {
//                Section(header:
//                            HStack {
//                                Image(uiImage: UIImage(named: "freezer") ?? UIImage(systemName: "snowflake")!)
//                                    .resizable()
//                                    .frame(width: 24, height: 24) // 調整圖片大小
//                                Text("Freezer")
//                                    .foregroundColor(.blue)
//                            }
//                ) {
//                    ForEach(filteredFoodItems.filter { $0.status == .freezer }) { item in
//                        FoodItemRow(
//                            item: item,
//                            moveToGrocery: moveToGrocery,
//                            moveToFridge: moveToFridge,
//                            moveToFreezer: moveToFreezer,
//                            onTap: { selectedItem in
//                                editingItem = selectedItem
//                            }
//                        )
//                    }
//                    .onDelete(perform: deleteItems)
//                    .listRowBackground(Color.clear)
//                    .listRowSeparator(.hidden)
//                }
//            }
//        }
//        .listStyle(PlainListStyle())
//    }
//}

//// MARK: - Preview
//
//struct FridgeView_Previews: PreviewProvider {
//    static var previews: some View {
//        let sampleFoodItem = FoodItem(
//            id: UUID().uuidString,
//            name: "Apple",
//            quantity: 3,
//            unit: "個",
//            status: .fridge,
//            daysRemaining: 5, 
//            expirationDate: Date(),
//            imageURL: nil
//        )
//        let store = FoodItemStore()
//        store.foodItems = [sampleFoodItem]
//        
//        return FridgeView()
//            .environmentObject(store)
//    }
//}
//
//import SwiftUI
//
//struct FridgeView: View {
//    @EnvironmentObject var foodItemStore: FoodItemStore
//    @State private var searchText = ""
//    @State private var editingItem: FoodItem?
//    @State private var showingProgressView = false
//    @State private var progressMessage = ""
//    @State private var showingMLIngredientView = false
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
//                GeometryReader { geometry in
//                    VStack {
//                        // 顯示背景圖片和文字
//                        if filteredFoodItems.isEmpty {
//                            VStack {
//                                Image("SearchFood")
//                                    .resizable()
//                                    .scaledToFill()
//                                    .frame(width: 350, height: 350)
//                                    .cornerRadius(10)
//                                    .shadow(radius: 8)
//                            }
//                            .frame(width: geometry.size.width, height: geometry.size.height)
//                            .background(Color.clear)
//                        }
//                    }
//                }
//                
//                VStack {
//                    FridgeListView(
//                        filteredFoodItems: filteredFoodItems,
//                        moveToGrocery: moveToGrocery,
//                        moveToFridge: moveToFridge,
//                        moveToFreezer: moveToFreezer,
//                        editingItem: $editingItem,
//                        deleteItems: deleteItems
//                    )
//                    
//                }
//            }
//            .sheet(item: $editingItem) { selectedItem in
//                let ingredient = convertToIngredient(item: selectedItem)
//                
//                MLIngredientView(onSave: { updatedIngredient in
//                    handleSave(updatedIngredient)
//                }, editingFoodItem: ingredient)
//            }
//            .navigationBarTitle("Fridge Storage 🥬", displayMode: .automatic)
//            .navigationBarItems(leading: EditButton().bold(), trailing: addButton)
//            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search food ingredient")
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
//        let filtered = foodItemStore.foodItems.filter { $0.status == .fridge || $0.status == .freezer }
//            .filter { item in
//                searchText.isEmpty || item.name.lowercased().contains(searchText.lowercased())
//            }
//        print("FridgeStorageView - Filtered items count: \(filtered.count)")
//        for item in filtered {
//            print(" - \(item.name)")
//        }
//        return filtered
//    }
//    
//    // 添加按鈕
//    var addButton: some View {
//        Button(action: {
//            // 創建一個新的空的 FoodItem 來觸發 sheet
//            editingItem = FoodItem(
//                id: UUID(),
//                name: "",
//                quantity: 1.00, // 默認值
//                unit: "unit",
//                status: .fridge, // 默認狀態
//                daysRemaining: 5,
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
//      func handleSave(_ ingredient: Ingredient) {
//          if let editing = editingItem, let index = foodItemStore.foodItems.firstIndex(where: { $0.id == editing.id }) {
//              // 更新操作
//              let today = Calendar.current.startOfDay(for: Date())
//              let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
//              foodItemStore.foodItems[index].name = ingredient.name
//              foodItemStore.foodItems[index].quantity = ingredient.quantity ?? 1.0
//              foodItemStore.foodItems[index].status = Status(rawValue: ingredient.storageMethod) ?? .fridge
//              foodItemStore.foodItems[index].daysRemaining = Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? 0
//              foodItemStore.foodItems[index].image = ingredient.image
//          } else {
//              // 添加新項，默認為 "Fridge" 或 "Freezer" 取決於用戶輸入
//              let today = Calendar.current.startOfDay(for: Date())
//              let expirationDate = Calendar.current.startOfDay(for: ingredient.expirationDate)
//              let status = ingredient.storageMethod.isEmpty ? Status.fridge : Status(rawValue: ingredient.storageMethod) ?? .fridge
//              let daysRemaining = status == .fridge ?  1 : 1
//              let newFoodItem = FoodItem(
//                  id: ingredient.id,
//                  name: ingredient.name,
//                  quantity: ingredient.quantity ?? 1.00,
//                  unit: ingredient.unit,
//                  status: status,
//                  daysRemaining: Calendar.current.dateComponents([.day], from: today, to: expirationDate).day ?? daysRemaining,
//                  image: ingredient.image
//              )
//              foodItemStore.foodItems.insert(newFoodItem, at: 0)
//              
//              // 顯示 ProgressView
//              showingProgressView = true
//              progressMessage = "Food added to \(newFoodItem.status.rawValue)!"
//              // 隱藏 ProgressView after delay
//              DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                  showingProgressView = false
//              }
//          }
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
//            let newExpirationDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
//            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: newExpirationDate).day ?? 1
//            foodItemStore.foodItems[index].daysRemaining = daysRemaining
//            
//            // 顯示 ProgressView
//            showingProgressView = true
//            progressMessage = "Food moved to Grocery List!"
//            // 隱藏 ProgressView after delay
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
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
//            let newExpirationDate = Calendar.current.date(byAdding: .day, value: storageMethod == "Fridge" ? 1 : 1, to: Date()) ?? Date()
//            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: newExpirationDate).day ?? 0
//            foodItemStore.foodItems[index].daysRemaining = daysRemaining
//            
//            // 顯示 ProgressView
//            showingProgressView = true
//            progressMessage = "Food added to \(storageMethod)!"
//            // 隱藏 ProgressView after delay
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
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
//            quantity: item.quantity,
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
//struct FridgeListView: View {
//    var filteredFoodItems: [FoodItem]
//    var moveToGrocery: (FoodItem) -> Void
//    var moveToFridge: (FoodItem) -> Void
//    var moveToFreezer: (FoodItem) -> Void
//    @Binding var editingItem: FoodItem?
//    var deleteItems: (IndexSet) -> Void
//    
//    var body: some View {
//        List {
//            // Fridge Section
//            if !filteredFoodItems.filter { $0.status == .fridge }.isEmpty {
//                Section(header:
//                            HStack {
//                                Image(uiImage: UIImage(named: "fridge") ?? UIImage(systemName: "refrigerator.fill")!)
//                                    .resizable()
//                                    .frame(width: 24, height: 24) // 調整圖片大小
//                                Text("Fridge")
//                                    .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
//                            }
//                ) {
//                    ForEach(filteredFoodItems.filter { $0.status == .fridge }) { item in
//                        FoodItemRow(
//                            item: item,
//                            moveToGrocery: moveToGrocery,
//                            moveToFridge: moveToFridge,
//                            moveToFreezer: moveToFreezer,
//                            onTap: { selectedItem in
//                                editingItem = selectedItem
//                            }
//                        )
//                    }
//                    .onDelete(perform: deleteItems)
//                    .listRowBackground(Color.clear)
//                    .listRowSeparator(.hidden)
//                }
//            }
//
//            // Freezer Section
//            if !filteredFoodItems.filter { $0.status == .freezer }.isEmpty {
//                Section(header:
//                            HStack {
//                                Image(uiImage: UIImage(named: "freezer") ?? UIImage(systemName: "snowflake")!)
//                                    .resizable()
//                                    .frame(width: 24, height: 24) // 調整圖片大小
//                                Text("Freezer")
//                                    .foregroundColor(.blue)
//                            }
//                ) {
//                    ForEach(filteredFoodItems.filter { $0.status == .freezer }) { item in
//                        FoodItemRow(
//                            item: item,
//                            moveToGrocery: moveToGrocery,
//                            moveToFridge: moveToFridge,
//                            moveToFreezer: moveToFreezer,
//                            onTap: { selectedItem in
//                                editingItem = selectedItem
//                            }
//                        )
//                    }
//                    .onDelete(perform: deleteItems)
//                    .listRowBackground(Color.clear)
//                    .listRowSeparator(.hidden)
//                }
//            }
//        }
//        .listStyle(PlainListStyle())
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
