//
//  GroceryListStore.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/14.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class GroceryListStore: ObservableObject {
    @Published var groceryItems: [FoodItem] = []
    private var listener: ListenerRegistration?
    private let firestoreService = FirestoreService()
    let listName: String 
    
    init(listName: String = "default") {
        self.listName = listName
        fetchGroceryItems()
    }
    
    func fetchGroceryItems() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No user is currently logged in.")
            return
        }
        
        listener = firestoreService.listenToGroceryItems(forUser: currentUser.uid, listName: listName) { [weak self] result in
            switch result {
            case .success(let items):
                DispatchQueue.main.async {
                    self?.groceryItems = items
                    print("Fetched \(items.count) grocery items from Firebase.")
                }
            case .failure(let error):
                print("Failed to fetch grocery items: \(error.localizedDescription)")
            }
        }
    }
    
    deinit {
        listener?.remove()
    }
}

