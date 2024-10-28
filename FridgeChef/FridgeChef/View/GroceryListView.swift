//
//  GroceryListView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

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
            ZStack(alignment: .bottomTrailing) {
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.4)
                .ignoresSafeArea()
               
                GeometryReader { geometry in
                    VStack {
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
                listenToFoodItems()
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
                    print("Fetched \(items.count) food items from Firebase.")
                    
                    let toBuyItems = items.filter { $0.status == .toBuy }
                    for item in toBuyItems {
                        self.scheduleToBuyNotification(for: item)
                    }
                }
            case .failure(let error):
                print("Failed to listen to food items: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleToBuyNotification(for item: FoodItem) {
        let content = UNMutableNotificationContent()
        content.title = "Grocery Reminder"
        content.body = "Don't forget to buy \(item.name)!"
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)
        
        let request = UNNotificationRequest(identifier: item.id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled for \(item.name)")
            }
        }
    }
    
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
   
            firestoreService.deleteFoodItem(forUser: currentUser.uid, foodItemId: item.id) { result in
                switch result {
                case .success():
                    print("Food item successfully deleted from Firebase.")
                case .failure(let error):
                    print("Failed to delete food item from Firebase: \(error.localizedDescription)")
                }
            }

            if let indexInFoodItems = foodItemStore.foodItems.firstIndex(where: { $0.id == item.id }) {
                foodItemStore.foodItems.remove(at: indexInFoodItems)
            }
        }
    }

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
            imageURL: nil
        )
        
        if let index = foodItemStore.foodItems.firstIndex(where: { $0.id == ingredient.id }) {

            foodItemStore.foodItems[index] = foodItem
            
            var updatedFields: [String: Any] = [
                "name": foodItem.name,
                "quantity": foodItem.quantity,
                "unit": foodItem.unit,
                "status": foodItem.status.rawValue,
                "daysRemaining": foodItem.daysRemaining,
                "expirationDate": Timestamp(date: foodItem.expirationDate ?? Date())
            ]
            
            if let image = ingredient.image {
                let imagePath = "users/\(currentUser.uid)/foodItems/\(foodItem.id)/image.jpg"
                firestoreService.uploadImage(image, path: imagePath) { result in
                    switch result {
                    case .success(let url):
                        updatedFields["imageURL"] = url
                      
                        firestoreService.updateFoodItem(forUser: currentUser.uid, foodItemId: foodItem.id, updatedFields: updatedFields) { result in
                         
                        }
                    case .failure(let error):
                        print("Failed to upload image: \(error.localizedDescription)")
                    }
                }
            } else {
              
                firestoreService.updateFoodItem(forUser: currentUser.uid, foodItemId: foodItem.id, updatedFields: updatedFields) { result in
           
                }
            }
            
        } else {
           
            foodItemStore.foodItems.append(foodItem)
            
            firestoreService.addFoodItem(forUser: currentUser.uid, foodItem: foodItem, image: ingredient.image) { result in
                switch result {
                case .success():
                    print("Food item successfully added to Firebase.")
                case .failure(let error):
                    print("Failed to add food item to Firebase: \(error.localizedDescription)")
                }
            }
        }
        
        editingItem = nil
       
        DispatchQueue.main.async {
            self.foodItemStore.objectWillChange.send()
        }
        
        showingProgressView = true
        progressMessage = "Food item saved!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            showingProgressView = false
        }
    }

    func moveToFridge(item: FoodItem) {
        moveToStorage(item: item, storageMethod: "Fridge")
    }

    func moveToFreezer(item: FoodItem) {
        moveToStorage(item: item, storageMethod: "Freezer")
    }

    func moveToStorage(item: FoodItem, storageMethod: String) {
        if let index = foodItemStore.foodItems.firstIndex(where: { $0.id == item.id }) {
            // Update status and expiration date
            foodItemStore.foodItems[index].status = Status(rawValue: storageMethod) ?? .fridge
            let newExpirationDate = Calendar.current.date(byAdding: .day, value: storageMethod == "Fridge" ? 5 : 14, to: Date()) ?? Date()
            foodItemStore.foodItems[index].expirationDate = newExpirationDate
            foodItemStore.foodItems[index].daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: newExpirationDate).day ?? 0

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

            DispatchQueue.main.async {
                self.foodItemStore.objectWillChange.send()
            }

            showingProgressView = true
            progressMessage = "Food moved to \(storageMethod)!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showingProgressView = false
            }

            print("Moved \(item.name) to \(storageMethod) Storage with status: \(foodItemStore.foodItems[index].status.rawValue)")
        }
    }

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
            imageURL: item.imageURL
        )
    }
    
    func convertToFoodItem(ingredient: Ingredient) -> FoodItem {
        return FoodItem(
            id: ingredient.id,
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
