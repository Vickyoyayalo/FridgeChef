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
    
    // Save user information to Firestore
    func saveUser(_ userData: [String: Any], uid: String, completion: @escaping (Result<Void, Error>) -> Void) {
        var dataWithID = userData
        dataWithID["uid"] = uid  // 明確地加入 uid
        
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
    
    // Fetch user by UID
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
    
    // Login with Apple
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
                        // 獲取使用者資料
                        let uid = authResult.user.uid
                        let email = authResult.user.email ?? "No Email"
                        let displayName = authResult.user.displayName ?? "Anonymous"
                        
                        // 準備要儲存的使用者資料
                        let userData: [String: Any] = [
                            "email": email,
                            "name": displayName
                        ]
                        
                        // 儲存到 Firestore
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
    
    // Send password reset
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
        // Prepare data as dictionary
        var data = [
            "id": foodItem.id,
            "name": foodItem.name,
            "quantity": foodItem.quantity,
            "unit": foodItem.unit,
            "status": foodItem.status.rawValue,
            "daysRemaining": foodItem.daysRemaining
        ] as [String: Any]
        
        // Handle optional expirationDate
        if let expirationDate = foodItem.expirationDate {
            data["expirationDate"] = Timestamp(date: expirationDate)
        }
        
        let foodItemRef = db.collection("users").document(userId).collection("foodItems").document(foodItem.id)
        
        // Upload image if available
        if let image = image {
            let imagePath = "users/\(userId)/foodItems/\(foodItem.id)/image.jpg"
            uploadImage(image, path: imagePath) { result in
                switch result {
                case .success(let url):
                    data["imageURL"] = url
                    // Save data to Firestore after image upload
                    foodItemRef.setData(data) { error in
                        if let error = error {
                            print("Failed to add food item: \(error.localizedDescription)")
                            completion(.failure(error))
                        } else {
                            print("Food item successfully added with ID: \(foodItem.id)")
                            completion(.success(()))
                        }
                    }
                case .failure(let error):
                    print("Failed to upload image: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        } else {
            // Save data without imageURL
            foodItemRef.setData(data) { error in
                if let error = error {
                    print("Failed to add food item: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("Food item successfully added with ID: \(foodItem.id)")
                    completion(.success(()))
                }
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
                        // Extract each field safely
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
                            foodItem.id = document.documentID  // 手動設置 id
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
    
    func saveMessage(_ message: Message, forUser userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            _ = try db.collection("users").document(userId).collection("chats").addDocument(from: message) { error in
                if let error = error {
                    print("Error saving message: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            print("Error encoding message: \(error)")
            completion(.failure(error))
        }
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
}

//import Foundation
//import Firebase
//import FirebaseAuth
//import FirebaseFirestore
//import FirebaseStorage
//import UIKit
//
//class FirestoreService {
//    private let db = FirebaseManager.shared.firestore
//    private let storage = Storage.storage()
//    
//    // Save user information to Firestore
//    func saveUser(_ userData: [String: Any], uid: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        var dataWithID = userData
//        dataWithID["uid"] = uid  // 明確地加入 uid
//        
//        db.collection("users").document(uid).setData(dataWithID) { error in
//            if let error = error {
//                print("Failed to save user data: \(error.localizedDescription)")
//                completion(.failure(error))
//            } else {
//                print("User data successfully saved to Firestore for user ID: \(uid)")
//                completion(.success(()))
//            }
//        }
//    }
//    
//    // Fetch user by UID
//    func fetchUser(byUid uid: String, completion: @escaping (User?, Error?) -> Void) {
//        db.collection("users").document(uid).getDocument { documentSnapshot, error in
//            if let error = error {
//                completion(nil, error)
//            } else if let documentSnapshot = documentSnapshot, documentSnapshot.exists {
//                do {
//                    let user = try documentSnapshot.data(as: User.self)
//                    completion(user, nil)
//                } catch {
//                    completion(nil, error)
//                }
//            }
//        }
//    }
//    
//    // 假設你有一個 loginWithApple 方法來處理 Apple 登入
//    func loginWithApple() {
//        let provider = OAuthProvider(providerID: "apple.com")
//        provider.getCredentialWith(nil) { credential, error in
//            if let error = error {
//                print("Apple login failed: \(error.localizedDescription)")
//                return
//            }
//            
//            if let credential = credential {
//                Auth.auth().signIn(with: credential) { authResult, error in
//                    if let error = error {
//                        print("Login failed: \(error.localizedDescription)")
//                    } else if let authResult = authResult {
//                        // 獲取使用者資料
//                        let uid = authResult.user.uid
//                        let email = authResult.user.email ?? "No Email"
//                        let displayName = authResult.user.displayName ?? "Anonymous"
//                        
//                        // 準備要儲存的使用者資料
//                        let userData: [String: Any] = [
//                            "email": email,
//                            "name": displayName
//                        ]
//                        
//                        // 儲存到 Firestore
//                        FirestoreService().saveUser(userData, uid: uid) { result in
//                            switch result {
//                            case .success():
//                                print("User data saved to Firestore")
//                            case .failure(let error):
//                                print("Failed to save user data: \(error.localizedDescription)")
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//    func sendPasswordReset(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        Auth.auth().sendPasswordReset(withEmail: email) { error in
//            if let error = error {
//                completion(.failure(error))
//            } else {
//                completion(.success(()))
//            }
//        }
//    }
//    
//    // MARK: - FoodItem CRUD Operations
//    
//    func addFoodItem(forUser userId: String, foodItem: FoodItem, image: UIImage?, completion: @escaping (Result<Void, Error>) -> Void) {
//        // Prepare data as dictionary
//        var data = [
//            "id": foodItem.id,
//            "name": foodItem.name,
//            "quantity": foodItem.quantity,
//            "unit": foodItem.unit,
//            "status": foodItem.status.rawValue,
//            "daysRemaining": foodItem.daysRemaining
//        ] as [String: Any]
//        
//        // Handle optional expirationDate
//        if let expirationDate = foodItem.expirationDate {
//            data["expirationDate"] = Timestamp(date: expirationDate)
//        }
//        
//        let foodItemRef = db.collection("users").document(userId).collection("foodItems").document(foodItem.id)
//        
//        // Upload image if available
//        if let image = image {
//            let imagePath = "users/\(userId)/foodItems/\(foodItem.id)/image.jpg"
//            uploadImage(image, path: imagePath) { result in
//                switch result {
//                case .success(let url):
//                    data["imageURL"] = url
//                    // Save data to Firestore after image upload
//                    foodItemRef.setData(data) { error in
//                        if let error = error {
//                            print("Failed to add food item: \(error.localizedDescription)")
//                            completion(.failure(error))
//                        } else {
//                            print("Food item successfully added with ID: \(foodItem.id)")
//                            completion(.success(()))
//                        }
//                    }
//                case .failure(let error):
//                    print("Failed to upload image: \(error.localizedDescription)")
//                    completion(.failure(error))
//                }
//            }
//        } else {
//            // Save data without imageURL
//            foodItemRef.setData(data) { error in
//                if let error = error {
//                    print("Failed to add food item: \(error.localizedDescription)")
//                    completion(.failure(error))
//                } else {
//                    print("Food item successfully added with ID: \(foodItem.id)")
//                    completion(.success(()))
//                }
//            }
//        }
//    }
//
//    
//    func fetchFoodItems(forUser userId: String, completion: @escaping (Result<[FoodItem], Error>) -> Void) {
//        let db = Firestore.firestore()
//           db.collection("users").document(userId).collection("foodItems")
//               .getDocuments(source: .cache) { (snapshot, error) in
//                if let error = error {
//                    completion(.failure(error))
//                } else {
//                    var foodItems: [FoodItem] = []
//                    snapshot?.documents.forEach { document in
//                        let data = document.data()
//                        // Extract each field safely
//                        let id = data["id"] as? String ?? document.documentID
//                        let name = data["name"] as? String ?? "Unknown"
//                        let quantity = data["quantity"] as? Double ?? 0.0
//                        let unit = data["unit"] as? String ?? ""
//                        let statusRaw = data["status"] as? String ?? Status.fridge.rawValue
//                        let status = Status(rawValue: statusRaw) ?? .fridge
//                        let daysRemaining = data["daysRemaining"] as? Int ?? 0
//                        let imageBase64 = data["imageBase64"] as? String
//                        let expirationTimestamp = data["expirationDate"] as? Timestamp
//                        let expirationDate = expirationTimestamp?.dateValue()
//                        
//                        let foodItem = FoodItem(
//                            id: id,
//                            name: name,
//                            quantity: quantity,
//                            unit: unit,
//                            status: status,
//                            daysRemaining: daysRemaining,
//                            expirationDate: expirationDate,
//                            imageURL: nil
//                        )
//                        foodItems.append(foodItem)
//                    }
//                    completion(.success(foodItems))
//                }
//            }
//    }
//    
//    func updateFoodItem(forUser userId: String, foodItemId: String, updatedFields: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
//        db.collection("users").document(userId).collection("foodItems").document(foodItemId)
//            .updateData(updatedFields) { error in
//                if let error = error {
//                    print("Failed to update food item: \(error.localizedDescription)")
//                    completion(.failure(error))
//                } else {
//                    print("Food item successfully updated with ID: \(foodItemId)")
//                    completion(.success(()))
//                }
//            }
//    }
//
//    
//    func deleteFoodItem(forUser userId: String, foodItemId: String, completion: @escaping (Result<Void, Error>) -> Void) {
//            db.collection("users").document(userId).collection("foodItems").document(foodItemId)
//                .delete { error in
//                    if let error = error {
//                        print("Failed to delete food item: \(error.localizedDescription)")
//                        completion(.failure(error))
//                    } else {
//                        print("Food item successfully deleted with ID: \(foodItemId)")
//                        completion(.success(()))
//                    }
//                }
//        }
//    // MARK: - Recipe CRUD Operations
//    
//    func addRecipe(recipe: Recipe, completion: @escaping (Result<Void, Error>) -> Void) {
//        do {
//            let _ = try db.collection("recipes").addDocument(from: recipe) { error in
//                if let error = error {
//                    completion(.failure(error))
//                } else {
//                    completion(.success(()))
//                }
//            }
//        } catch {
//            completion(.failure(error))
//        }
//    }
//    
//    func fetchRecipes(completion: @escaping (Result<[Recipe], Error>) -> Void) {
//        db.collection("recipes")
//            .getDocuments { (snapshot, error) in
//                if let error = error {
//                    completion(.failure(error))
//                } else {
//                    var recipes: [Recipe] = []
//                    snapshot?.documents.forEach { document in
//                        if let recipe = try? document.data(as: Recipe.self) {
//                            recipes.append(recipe)
//                        }
//                    }
//                    completion(.success(recipes))
//                }
//            }
//    }
//    
//    // MARK: - Grocery List CRUD Operations
//    
//    func addGroceryItemToGroceryList(forUser userId: String, item: FoodItem, listName: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        let groceryItemData: [String: Any] = [
//            "name": item.name,
//            "quantity": item.quantity,
//            "unit": item.unit,
//            "isPurchased": false,
//            "status": item.status.rawValue,
//            "expirationDate": item.expirationDate as Any
//        ]
//        
//        db.collection("users").document(userId).collection("groceryLists").document(listName).collection("items")
//            .addDocument(data: groceryItemData) { error in
//                if let error = error {
//                    completion(.failure(error))
//                } else {
//                    completion(.success(()))
//                }
//            }
//    }
//    
//    func fetchGroceryList(forUser userId: String, listName: String, completion: @escaping (Result<[FoodItem], Error>) -> Void) {
//        db.collection("users").document(userId).collection("groceryLists").document(listName).collection("items")
//            .getDocuments { (snapshot, error) in
//                if let error = error {
//                    completion(.failure(error))
//                } else {
//                    var groceryItems: [FoodItem] = []
//                    snapshot?.documents.forEach { document in
//                        if let groceryItem = try? document.data(as: FoodItem.self) {
//                            groceryItems.append(groceryItem)
//                        }
//                    }
//                    completion(.success(groceryItems))
//                }
//            }
//    }
//    
//    func updateGroceryItem(forUser userId: String, listName: String, itemId: String, updatedFields: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
//        db.collection("users").document(userId).collection("groceryLists").document(listName).collection("items").document(itemId)
//            .updateData(updatedFields) { error in
//                if let error = error {
//                    completion(.failure(error))
//                } else {
//                    completion(.success(()))
//                }
//            }
//    }
//    func deleteGroceryItem(forUser userId: String, listName: String, itemId: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        db.collection("users").document(userId).collection("groceryLists").document(listName).collection("items").document(itemId)
//            .delete { error in
//                if let error = error {
//                    completion(.failure(error))
//                } else {
//                    completion(.success(()))
//                }
//            }
//    }
//    
//    // MARK: - Image Upload
//    
//    func uploadImage(_ image: UIImage, path: String, completion: @escaping (Result<String, Error>) -> Void) {
//        guard let imageData = image.jpegData(compressionQuality: 0.6) else {  // Adjust compression as needed
//            completion(.failure(NSError(domain: "ImageConversionError", code: -1, userInfo: nil)))
//            return
//        }
//        
//        let storageRef = storage.reference().child(path)
//        let metadata = StorageMetadata()
//        metadata.contentType = "image/jpeg"
//        
//        storageRef.putData(imageData, metadata: metadata) { (_, error) in
//            if let error = error {
//                completion(.failure(error))
//            } else {
//                storageRef.downloadURL { (url, error) in
//                    if let error = error {
//                        completion(.failure(error))
//                    } else if let url = url {
//                        completion(.success(url.absoluteString))
//                    }
//                }
//            }
//        }
//    }
//
//    
//    // MARK: - Real-time Listener
//    
//    func listenToFoodItems(forUser userId: String, onUpdate: @escaping (Result<[FoodItem], Error>) -> Void) -> ListenerRegistration {
//            return db.collection("users").document(userId).collection("foodItems")
//                .addSnapshotListener { (snapshot, error) in
//                    if let error = error {
//                        onUpdate(.failure(error))
//                    } else {
//                        var foodItems: [FoodItem] = []
//                        snapshot?.documents.forEach { document in
//                            do {
//                                var foodItem = try document.data(as: FoodItem.self)
//                                foodItem.id = document.documentID  // 手動設置 id
//                                if let expirationTimestamp = document.get("expirationDate") as? Timestamp {
//                                    foodItem.expirationDate = expirationTimestamp.dateValue()
//                                }
//                                foodItems.append(foodItem)
//                            } catch {
//                                print("Failed to decode FoodItem: \(error.localizedDescription)")
//                            }
//                        }
//                        onUpdate(.success(foodItems))
//                    }
//                }
//        }
//    }
//class FirestoreChatService {
//    let db = Firestore.firestore()
//    
//    func saveMessage(_ message: Message, forUser userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        do {
//            _ = try db.collection("users").document(userId).collection("chats").addDocument(from: message) { error in
//                if let error = error {
//                    print("Error saving message: \(error)")
//                    completion(.failure(error))
//                } else {
//                    completion(.success(()))
//                }
//            }
//        } catch {
//            print("Error encoding message: \(error)")
//            completion(.failure(error))
//        }
//    }
//    
//    func fetchMessages(forUser userId: String, completion: @escaping (Result<[Message], Error>) -> Void) {
//        db.collection("users").document(userId).collection("chats").order(by: "timestamp").addSnapshotListener { snapshot, error in
//            if let error = error {
//                print("Error fetching messages: \(error)")
//                completion(.failure(error))
//                return
//            }
//            
//            guard let documents = snapshot?.documents else {
//                print("No messages found")
//                completion(.success([]))
//                return
//            }
//            
//            let messages = documents.compactMap { document -> Message? in
//                try? document.data(as: Message.self)
//            }
//            
//            completion(.success(messages))
//        }
//    }
//}

//import FirebaseFirestore
//import FirebaseAuth
//
//// FirestoreService: 用來處理與 Firestore 資料庫相關的操作
//class FirestoreService {
//    private let db = FirebaseManager.shared.firestore
//
//    // Save user information to Firestore
//    func saveUser(_ userData: [String: Any], uid: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        var dataWithID = userData
//        dataWithID["uid"] = uid  // 明確地加入 uid
//
//        do {
//             db.collection("users").document(uid).setData(dataWithID) { error in
//                if let error = error {
//                    completion(.failure(error))
//                } else {
//                    completion(.success(()))
//                }
//            }
//        } catch let error {
//            completion(.failure(error))
//        }
//    }
//
//    func sendPasswordReset(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
//            Auth.auth().sendPasswordReset(withEmail: email) { error in
//                if let error = error {
//                    completion(.failure(error))
//                } else {
//                    completion(.success(()))
//                }
//            }
//        }
//    // Fetch user by UID
//    func fetchUser(byUid uid: String, completion: @escaping (User?, Error?) -> Void) {
//        db.collection("users").document(uid).getDocument { documentSnapshot, error in
//            if let error = error {
//                completion(nil, error)
//            } else if let documentSnapshot = documentSnapshot, documentSnapshot.exists {
//                do {
//                    let user = try documentSnapshot.data(as: User.self)
//                    completion(user, nil)
//                } catch {
//                    completion(nil, error)
//                }
//            }
//        }
//    }
//    // 儲存食材 (Ingredient) 到 Firestore
////    func saveIngredient(_ ingredient: Ingredient, completion: @escaping (Result<Void, Error>) -> Void) {
////        do {
////            if let id = ingredient.id {
////                // 更新已存在的食材
////                try db.collection("ingredients").document(id).setData(from: ingredient) { error in
////                    if let error = error {
////                        completion(.failure(error))
////                    } else {
////                        completion(.success(()))
////                    }
////                }
////            } else {
////                // 新增新的食材
////                try db.collection("ingredients").addDocument(from: ingredient) { error in
////                    if let error = error {
////                        completion(.failure(error))
////                    } else {
////                        completion(.success(()))
////                    }
////                }
////            }
////        } catch let error {
////            completion(.failure(error))
////        }
////    }
//
//    // 從 Firestore 中讀取所有的食材 (Ingredients)
////    func fetchIngredients(completion: @escaping ([Ingredient]?, Error?) -> Void) {
////        db.collection("ingredients").getDocuments { snapshot, error in
////            if let error = error {
////                completion(nil, error)
////            } else {
////                let ingredients = snapshot?.documents.compactMap { doc in
////                    do {
////                        return try doc.data(as: Ingredient.self)
////                    } catch {
////                        print("Error decoding ingredient: \(error.localizedDescription)")
////                        return nil
////                    }
////                }
////                completion(ingredients, nil)
////            }
////        }
////    }
////
////    // 刪除食材
////    func deleteIngredient(_ ingredientId: String, completion: @escaping (Error?) -> Void) {
////        db.collection("ingredients").document(ingredientId).delete { error in
////            if let error = error {
////                print("Error deleting ingredient with ID \(ingredientId): \(error)")
////                completion(error)
////            } else {
////                print("Ingredient with ID \(ingredientId) deleted successfully.")
////                completion(nil)
////            }
////        }
////    }
//
//    // 儲存食譜 (Recipe) 到 Firestore，使用 Result 來保持一致性
////    func saveRecipe(_ recipe: Recipe, completion: @escaping (Result<Void, Error>) -> Void) {
////        do {
////            if let id = recipe.id {
////                // 更新已存在的食譜
////                try db.collection("recipes").document(id).setData(from: recipe) { error in
////                    if let error = error {
////                        completion(.failure(error))
////                    } else {
////                        completion(.success(()))
////                    }
////                }
////            } else {
////                // 新增新的食譜
////                try db.collection("recipes").addDocument(from: recipe) { error in
////                    if let error = error {
////                        completion(.failure(error))
////                    } else {
////                        completion(.success(()))
////                    }
////                }
////            }
////        } catch let error {
////            completion(.failure(error))
////        }
////    }
////
//    // 從 Firestore 中讀取所有的食譜 (Recipes)
////    func fetchRecipes(completion: @escaping ([Recipe]?, Error?) -> Void) {
////        db.collection("recipes").getDocuments { snapshot, error in
////            if let error = error {
////                print("Error fetching recipes: \(error)")
////                completion(nil, error)
////            } else {
////                let recipes = snapshot?.documents.compactMap { doc in
////                    try? doc.data(as: Recipe.self)
////                }
////                completion(recipes, nil)
////            }
////        }
////    }
//}
//
