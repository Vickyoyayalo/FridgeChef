//
//  FoodItemStore.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/28.
//

import Combine
import WidgetKit
import Foundation
import FirebaseAuth
import FirebaseFirestore

protocol FoodItemStoreProtocol: ObservableObject {
    var foodItems: [FoodItem] { get set }
    func addFoodItem(_ item: FoodItem)
    func removeFoodItem(withId id: String)
    func isIngredientInCart(_ ingredient: String) -> Bool
}

class FoodItemStore: ObservableObject {
    @Published var foodItems: [FoodItem] = []
    private var listener: ListenerRegistration?
    
    var expiringItems: [FoodItem] {
        foodItems.filter { $0.status != .toBuy && $0.daysRemaining <= 3 && $0.daysRemaining >= 0 }
    }
    
    var expiredItems: [FoodItem] {
        foodItems.filter { $0.status != .toBuy && $0.daysRemaining < 0 }
    }
    
    init() {
        fetchFoodItems()
    }
    
    func updateWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "FridgeChefWidget")
    }
    
    func saveFoodItemsToUserDefaults(_ foodItems: [FoodItem]) {
        let sharedDefaults = UserDefaults(suiteName: "group.com.vickyoyaya.FridgeChef")
        
        let simpleItems = foodItems.map { item in
            SimpleFoodItem(
                id: item.id,
                name: item.name,
                quantity: item.quantity,
                unit: item.unit,
                daysRemaining: item.daysRemaining,
                status: item.status
            )
        }
        
        if let encodedData = try? JSONEncoder().encode(simpleItems) {
            sharedDefaults?.set(encodedData, forKey: "foodItems")
            updateWidget()
        }
    }
    
    func addFoodItem(_ item: FoodItem) {
        if !foodItems.contains(where: { $0.id == item.id }) {
            foodItems.append(item)
        }
    }
    
    func removeFoodItem(withId id: String) {
        if let index = foodItems.firstIndex(where: { $0.id == id }) {
            foodItems.remove(at: index)
        }
    }
    
    func isIngredientInCart(_ ingredient: String) -> Bool {
        return foodItems.contains { $0.name.lowercased() == ingredient.lowercased() }
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
                    self?.foodItems = items
                    self?.saveFoodItemsToUserDefaults(items)
                    
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

struct SimpleFoodItem: Identifiable, Codable {
    var id: String
    var name: String
    var quantity: Double
    var unit: String
    var daysRemaining: Int
    var status: Status
}
