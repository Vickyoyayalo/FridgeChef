//
//  FridgeView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/19.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import UserNotifications

protocol NotificationCenterProtocol {
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?)
}

extension UNUserNotificationCenter: NotificationCenterProtocol {}

struct FridgeView: View {
    @ObservedObject var foodItemStore: FoodItemStore
    @State private var searchText = ""
    @State private var editingItem: FoodItem?
    @State private var showingProgressView = false
    @State private var progressMessage = ""
    @State private var showingMLIngredientView = false
    @State private var listenerRegistration: ListenerRegistration?
    
    let firestoreService = FirestoreService()
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                
                GeometryReader { geometry in
                    VStack {
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
                        deleteItems: deleteItems
                    )
                }
            }
            .sheet(item: $editingItem) { selectedItem in
                let ingredient = convertToIngredient(item: selectedItem)
                
                MLIngredientView(
                    onSave: { updatedIngredient in
                        handleSave(updatedIngredient)
                    },
                    editingFoodItem: ingredient,
                    foodItemStore: foodItemStore
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
                listenToFoodItems()
                checkPendingNotifications()
            }
            .onDisappear {
                listenerRegistration?.remove()
                listenerRegistration = nil
            }
        }
    }
    
    func listenToFoodItems() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user is currently logged in.")
            return
        }
        
        listenerRegistration = firestoreService.listenToFoodItems(forUser: currentUser.uid) { result in
            switch result {
            case .success(let items):
                DispatchQueue.main.async {
                    self.foodItemStore.foodItems = items
                    print("Real-time update: Fetched \(items.count) food items from Firebase.")
                    
                    for item in items where
                    item.daysRemaining <= 3 {
                        self.scheduleExpirationNotification(for: item)
                    }
                }
            case .failure(let error):
                print("Failed to listen to food items: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleExpirationNotification(for item: FoodItem, notificationCenter: NotificationCenterProtocol = UNUserNotificationCenter.current()) {
        let content = UNMutableNotificationContent()
        if item.daysRemaining < 0 {
            let daysAgo = abs(item.daysRemaining)
            let dayText = daysAgo == 1 ? "day" : "days"
            content.title = "Expired Alert‼️"
            content.body = "\(item.name) expired \(daysAgo) \(dayText) ago!"
        } else {
            let dayText = item.daysRemaining == 1 ? "day" : "days"
            content.title = "Expiration Alert‼️"
            content.body = "\(item.name) is about to expire in \(item.daysRemaining) \(dayText)!"
        }
        content.sound = UNNotificationSound.default
        
        let timeInterval = item.daysRemaining < 0 ? 1 : TimeInterval(item.daysRemaining * 24 * 60 * 60)
        guard timeInterval > 0 else {
            print("Invalid time interval for notification")
            return
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: item.id, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled for \(item.name)")
            }
        }
    }
    
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
    
    var addButton: some View {
        Button(action: {
            showingMLIngredientView = true
        }, label: {
            Image(systemName: "plus")
                .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                .bold()
        })
        .sheet(isPresented: $showingMLIngredientView) {
            MLIngredientView(
                onSave: { newIngredient in
                    handleSave(newIngredient)
                },
                foodItemStore: foodItemStore
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
            firestoreService.deleteFoodItem(forUser: currentUser.uid, foodItemId: item.id) { result in
                switch result {
                case .success:
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
                        firestoreService.updateFoodItem(forUser: currentUser.uid, foodItemId: foodItem.id, updatedFields: updatedFields) { _ in
                        }
                    case .failure(let error):
                        print("Failed to upload image: \(error.localizedDescription)")
                    }
                }
            } else {
                firestoreService.updateFoodItem(forUser: currentUser.uid, foodItemId: foodItem.id, updatedFields: updatedFields) { _ in
                }
            }
            
        } else {
            foodItemStore.foodItems.append(foodItem)
            
            firestoreService.addFoodItem(forUser: currentUser.uid, foodItem: foodItem, image: ingredient.image) { result in
                switch result {
                case .success:
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
    
    func moveToGrocery(item: FoodItem) {
        if let index = foodItemStore.foodItems.firstIndex(where: { $0.id == item.id }) {
            foodItemStore.foodItems[index].status = .toBuy
            let newExpirationDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: newExpirationDate).day ?? 1
            foodItemStore.foodItems[index].expirationDate = newExpirationDate
            
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
                case .success:
                    print("Food item successfully updated in Firebase.")
                case .failure(let error):
                    print("Failed to update food item in Firebase: \(error.localizedDescription)")
                }
            }
            
            showingProgressView = true
            progressMessage = "Food moved to Grocery List!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showingProgressView = false
            }
            
            print("Moved \(item.name) to Grocery List with status: \(foodItemStore.foodItems[index].status.rawValue)")
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
            let newStatus = Status(rawValue: storageMethod) ?? .fridge
            foodItemStore.foodItems[index].status = newStatus
            let newExpirationDate = Calendar.current.date(byAdding: .day, value: storageMethod == "Fridge" ? 5 : 14, to: Date()) ?? Date()
            foodItemStore.foodItems[index].expirationDate = newExpirationDate
            let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: newExpirationDate).day ?? 0
            
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
                case .success:
                    print("Food item successfully updated in Firebase.")
                case .failure(let error):
                    print("Failed to update food item in Firebase: \(error.localizedDescription)")
                }
            }
            
            DispatchQueue.main.async {
                self.foodItemStore.objectWillChange.send()
            }
            
            showingProgressView = true
            progressMessage = "Moved to \(storageMethod)!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showingProgressView = false
            }
            
            print("Moved \(item.name) to \(storageMethod) Storage with status: \(foodItemStore.foodItems[index].status.rawValue)")
        }
    }
    
    func convertToIngredient(item: FoodItem) -> Ingredient {
        return Ingredient(
            id: item.id,
            name: item.name,
            quantity: item.quantity,
            amount: 1.0,
            unit: item.unit,
            expirationDate: item.expirationDate ?? Date(),
            storageMethod: item.status.rawValue,
            image: nil,
            imageURL: item.imageURL
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
            if !filteredFoodItems.filter({ $0.status == .fridge }).isEmpty {
                Section(header: HStack {
                    Image(uiImage: UIImage(named: "fridge") ?? UIImage(systemName: "refrigerator.fill")!)
                        .resizable()
                        .frame(width: 24, height: 24)
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
            
            if !filteredFoodItems.filter({ $0.status == .freezer }).isEmpty {
                Section(header:
                            HStack {
                    Image(uiImage: UIImage(named: "freezer") ?? UIImage(systemName: "snowflake")!)
                        .resizable()
                        .frame(width: 24, height: 24)
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
            expirationDate: Date(),
            imageURL: nil
        )
        let store = FoodItemStore()
        store.foodItems = [sampleFoodItem]
        
        return FridgeView(foodItemStore: store)
            .environmentObject(store)
    }
}

extension FridgeView {
    func checkPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            for request in requests {
                print("Pending notification: \(request.identifier) - \(request.content.body)")
            }
            print("Total pending notifications: \(requests.count)")
        }
    }
}
