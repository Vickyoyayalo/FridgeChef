//
//  FirestoreService.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//
import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

class FirestoreService {
    private let db = FirebaseManager.shared.firestore
    private let storage = Storage.storage()
    
    func saveUser(_ userData: [String: Any], uid: String, completion: @escaping (Result<Void, Error>) -> Void) {
        var dataWithID = userData
        dataWithID["uid"] = uid
        
        db.collection("users").document(uid).setData(dataWithID) { error in
            if let error = error {
                print("Failed to save user data: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("User data successfully saved to Firestore for user ID: \(uid)")
                completion(.success(()))
            }
        }
    }
    
    func fetchUser(byUid uid: String, completion: @escaping (User?, Error?) -> Void) {
        db.collection("users").document(uid).getDocument { documentSnapshot, error in
            if let error = error {
                completion(nil, error)
            } else if let documentSnapshot = documentSnapshot, documentSnapshot.exists {
                do {
                    let user = try documentSnapshot.data(as: User.self)
                    completion(user, nil)
                } catch {
                    completion(nil, error)
                }
            }
        }
    }
    
    func loginWithApple() {
        let provider = OAuthProvider(providerID: "apple.com")
        provider.getCredentialWith(nil) { credential, error in
            if let error = error {
                print("Apple login failed: \(error.localizedDescription)")
                return
            }
            
            if let credential = credential {
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        print("Login failed: \(error.localizedDescription)")
                    } else if let authResult = authResult {
                     
                        let uid = authResult.user.uid
                        let email = authResult.user.email ?? "No Email"
                        let displayName = authResult.user.displayName ?? "Anonymous"
                        let userData: [String: Any] = [
                            "email": email,
                            "name": displayName
                        ]
                        
                        self.saveUser(userData, uid: uid) { result in
                            switch result {
                            case .success():
                                print("User data saved to Firestore")
                            case .failure(let error):
                                print("Failed to save user data: \(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func sendPasswordReset(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - FoodItem CRUD Operations
    
    func addFoodItem(forUser userId: String, foodItem: FoodItem, image: UIImage?, completion: @escaping (Result<Void, Error>) -> Void) {
        var hasCompleted = false
        var data = [
            "id": foodItem.id,
            "name": foodItem.name,
            "quantity": foodItem.quantity,
            "unit": foodItem.unit,
            "status": foodItem.status.rawValue,
            "daysRemaining": foodItem.daysRemaining
        ] as [String: Any]
        
        if let expirationDate = foodItem.expirationDate {
            data["expirationDate"] = Timestamp(date: expirationDate)
        }

        let foodItemRef = db.collection("users").document(userId).collection("foodItems").document(foodItem.id)

        if let image = image {
            let imagePath = "users/\(userId)/foodItems/\(foodItem.id)/image.jpg"
            uploadImage(image, path: imagePath) { result in
                guard !hasCompleted else { return }
                switch result {
                case .success(let url):
                    data["imageURL"] = url
                    foodItemRef.setData(data) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
                hasCompleted = true
            }
        } else {
            foodItemRef.setData(data) { error in
                guard !hasCompleted else { return }
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
                hasCompleted = true
            }
        }
    }


    func fetchFoodItems(forUser userId: String, completion: @escaping (Result<[FoodItem], Error>) -> Void) {
        db.collection("users").document(userId).collection("foodItems")
            .getDocuments(source: .cache) { (snapshot, error) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    var foodItems: [FoodItem] = []
                    snapshot?.documents.forEach { document in
                        let data = document.data()
                        let id = data["id"] as? String ?? document.documentID
                        let name = data["name"] as? String ?? "Unknown"
                        let quantity = data["quantity"] as? Double ?? 0.0
                        let unit = data["unit"] as? String ?? ""
                        let statusRaw = data["status"] as? String ?? Status.fridge.rawValue
                        let status = Status(rawValue: statusRaw) ?? .fridge
                        let daysRemaining = data["daysRemaining"] as? Int ?? 0
                        let expirationTimestamp = data["expirationDate"] as? Timestamp
                        let expirationDate = expirationTimestamp?.dateValue()
                        
                        let foodItem = FoodItem(
                            id: id,
                            name: name,
                            quantity: quantity,
                            unit: unit,
                            status: status,
                            daysRemaining: daysRemaining,
                            expirationDate: expirationDate,
                            imageURL: data["imageURL"] as? String
                        )
                        foodItems.append(foodItem)
                    }
                    completion(.success(foodItems))
                }
            }
    }
    
    func updateFoodItem(forUser userId: String, foodItemId: String, updatedFields: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("users").document(userId).collection("foodItems").document(foodItemId)
            .updateData(updatedFields) { error in
                if let error = error {
                    print("Failed to update food item: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("Food item successfully updated with ID: \(foodItemId)")
                    completion(.success(()))
                }
            }
    }
    
    func deleteFoodItem(forUser userId: String, foodItemId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("users").document(userId).collection("foodItems").document(foodItemId)
            .delete { error in
                if let error = error {
                    print("Failed to delete food item: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("Food item successfully deleted with ID: \(foodItemId)")
                    completion(.success(()))
                }
            }
    }
    
    // MARK: - Recipe CRUD Operations
    
    func addRecipe(recipe: Recipe, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let _ = try db.collection("recipes").addDocument(from: recipe) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func fetchRecipes(completion: @escaping (Result<[Recipe], Error>) -> Void) {
        db.collection("recipes")
            .getDocuments { (snapshot, error) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    var recipes: [Recipe] = []
                    snapshot?.documents.forEach { document in
                        if let recipe = try? document.data(as: Recipe.self) {
                            recipes.append(recipe)
                        }
                    }
                    completion(.success(recipes))
                }
            }
    }
    
    // MARK: - Grocery List CRUD Operations
    
    func addGroceryItemToGroceryList(forUser userId: String, item: FoodItem, listName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let groceryItemData: [String: Any] = [
            "name": item.name,
            "quantity": item.quantity,
            "unit": item.unit,
            "isPurchased": false,
            "status": item.status.rawValue,
            "expirationDate": item.expirationDate as Any
        ]
        
        db.collection("users").document(userId).collection("groceryLists").document(listName).collection("items")
            .addDocument(data: groceryItemData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    func fetchGroceryList(forUser userId: String, listName: String, completion: @escaping (Result<[FoodItem], Error>) -> Void) {
        db.collection("users").document(userId).collection("groceryLists").document(listName).collection("items")
            .getDocuments { (snapshot, error) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    var groceryItems: [FoodItem] = []
                    snapshot?.documents.forEach { document in
                        if let groceryItem = try? document.data(as: FoodItem.self) {
                            groceryItems.append(groceryItem)
                        }
                    }
                    completion(.success(groceryItems))
                }
            }
    }
    
    func updateGroceryItem(forUser userId: String, listName: String, itemId: String, updatedFields: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("users").document(userId).collection("groceryLists").document(listName).collection("items").document(itemId)
            .updateData(updatedFields) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    func deleteGroceryItem(forUser userId: String, listName: String, itemId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("users").document(userId).collection("groceryLists").document(listName).collection("items").document(itemId)
            .delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    // MARK: - Listen to Grocery Items
        func listenToGroceryItems(forUser userId: String, listName: String, onUpdate: @escaping (Result<[FoodItem], Error>) -> Void) -> ListenerRegistration {
            return db.collection("users").document(userId).collection("groceryLists").document(listName).collection("items")
                .addSnapshotListener { (snapshot, error) in
                    if let error = error {
                        onUpdate(.failure(error))
                    } else {
                        var groceryItems: [FoodItem] = []
                        snapshot?.documents.forEach { document in
                            do {
                                var foodItem = try document.data(as: FoodItem.self)
                                foodItem.id = document.documentID  // 手動設置 id
                                if let expirationTimestamp = document.get("expirationDate") as? Timestamp {
                                    foodItem.expirationDate = expirationTimestamp.dateValue()
                                }
                                if let imageURL = document.get("imageURL") as? String {
                                    foodItem.imageURL = imageURL
                                }
                                groceryItems.append(foodItem)
                            } catch {
                                print("Failed to decode FoodItem: \(error.localizedDescription)")
                            }
                        }
                        onUpdate(.success(groceryItems))
                    }
                }
        }
    
    // MARK: - Image Upload
    
    func uploadImage(_ image: UIImage, path: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get image data."])))
            return
        }
        
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { (_, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                storageRef.downloadURL { (url, error) in
                    if let error = error {
                        completion(.failure(error))
                    } else if let url = url {
                        completion(.success(url.absoluteString))
                    }
                }
            }
        }
    }
    
    // MARK: - Real-time Listener
    
    func listenToFoodItems(forUser userId: String, onUpdate: @escaping (Result<[FoodItem], Error>) -> Void) -> ListenerRegistration {
        return db.collection("users").document(userId).collection("foodItems")
            .addSnapshotListener { (snapshot, error) in
                if let error = error {
                    onUpdate(.failure(error))
                } else {
                    var foodItems: [FoodItem] = []
                    snapshot?.documents.forEach { document in
                        do {
                            var foodItem = try document.data(as: FoodItem.self)
                            foodItem.id = document.documentID
                            if let expirationTimestamp = document.get("expirationDate") as? Timestamp {
                                foodItem.expirationDate = expirationTimestamp.dateValue()
                            }
                            if let imageURL = document.get("imageURL") as? String {
                                foodItem.imageURL = imageURL
                            }
                            foodItems.append(foodItem)
                        } catch {
                            print("Failed to decode FoodItem: \(error.localizedDescription)")
                        }
                    }
                    onUpdate(.success(foodItems))
                }
            }
    }
    
    // MARK: - Message CRUD Operations
    func getCachedResponse(message: String, completion: @escaping (Result<CachedResponse?, Error>) -> Void) {
           db.collection("cachedResponses")
               .whereField("message", isEqualTo: message)
               .order(by: "timestamp", descending: true)
               .limit(to: 1)
               .getDocuments { snapshot, error in
                   if let error = error {
                       completion(.failure(error))
                       return
                   }
                   if let document = snapshot?.documents.first {
                       do {
                           let cachedResponse = try document.data(as: CachedResponse.self)
                           completion(.success(cachedResponse))
                       } catch {
                           completion(.failure(error))
                       }
                   } else {
                       completion(.success(nil))
                   }
               }
       }
       
    func saveCachedResponse(message: String, response: String, completion: @escaping (Result<Void, Error>) -> Void) {
           guard let currentUser = Auth.auth().currentUser else {
               print("No user is currently logged in.")
               completion(.failure(NSError(domain: "NoUser", code: 401, userInfo: nil)))
               return
           }

           let standardizedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)

           let cachedResponse = CachedResponse(
               id: nil,
               userId: currentUser.uid,
               message: standardizedMessage,
               response: response,
               timestamp: Date()
           )

           do {
               _ = try db.collection("cachedResponses").addDocument(from: cachedResponse)
               completion(.success(()))
           } catch {
               completion(.failure(error))
           }
       }
    

    func saveMessage(_ message: Message, forUser userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            _ = try db.collection("users").document(userId).collection("chats").addDocument(from: message)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    func listenForMessages(forUser userId: String, after date: Date, completion: @escaping (Result<[Message], Error>) -> Void) -> ListenerRegistration? {
        let query = db.collection("users").document(userId).collection("chats")
                        .whereField("timestamp", isGreaterThan: date)
                        .order(by: "timestamp", descending: false)
        
        let listener = query.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let messages = documents.compactMap { try? $0.data(as: Message.self) }
            completion(.success(messages))
        }
        
        return listener
    }
    
    func fetchMessages(forUser userId: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        db.collection("users").document(userId).collection("chats").order(by: "timestamp").addSnapshotListener { snapshot, error in
            if let error = error {
                print("Error fetching messages: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No messages found")
                completion(.success([]))
                return
            }
            
            let messages = documents.compactMap { document -> Message? in
                try? document.data(as: Message.self)
            }
            
            completion(.success(messages))
        }
    }
    
    //MARK: -take data from Firebase
    func fetchFavoriteRecipes(completion: @escaping ([Int]) -> Void) {
            guard let userId = Auth.auth().currentUser?.uid else {
                print("User not logged in")
                completion([])
                return
            }
            
            let favoritesRef = db.collection("users").document(userId).collection("favorites")
            
            favoritesRef.getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching favorites: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                let favoriteIDs = snapshot?.documents.compactMap { $0["recipeId"] as? Int } ?? []
                completion(favoriteIDs)
            }
        }
    
    func addFavorite(recipeId: Int) {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            let favoritesRef = db.collection("users").document(userId).collection("favorites")
            
            favoritesRef.document(String(recipeId)).setData(["recipeId": recipeId])
        }

        func removeFavorite(recipeId: Int) {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            let favoritesRef = db.collection("users").document(userId).collection("favorites")
            
            favoritesRef.document(String(recipeId)).delete()
        }

}
