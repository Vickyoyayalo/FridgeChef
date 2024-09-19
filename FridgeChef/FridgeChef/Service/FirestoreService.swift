//
//  FirestoreService.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import FirebaseFirestore
import FirebaseAuth

// FirestoreService: 用來處理與 Firestore 資料庫相關的操作
class FirestoreService {
    private let db = FirebaseManager.shared.firestore
    
    // Save user information to Firestore
    func saveUser(_ userData: [String: Any], uid: String, completion: @escaping (Result<Void, Error>) -> Void) {
        var dataWithID = userData
        dataWithID["uid"] = uid  // 明確地加入 uid

        do {
             db.collection("users").document(uid).setData(dataWithID) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch let error {
            completion(.failure(error))
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
    // 儲存食材 (Ingredient) 到 Firestore
//    func saveIngredient(_ ingredient: Ingredient, completion: @escaping (Result<Void, Error>) -> Void) {
//        do {
//            if let id = ingredient.id {
//                // 更新已存在的食材
//                try db.collection("ingredients").document(id).setData(from: ingredient) { error in
//                    if let error = error {
//                        completion(.failure(error))
//                    } else {
//                        completion(.success(()))
//                    }
//                }
//            } else {
//                // 新增新的食材
//                try db.collection("ingredients").addDocument(from: ingredient) { error in
//                    if let error = error {
//                        completion(.failure(error))
//                    } else {
//                        completion(.success(()))
//                    }
//                }
//            }
//        } catch let error {
//            completion(.failure(error))
//        }
//    }

    // 從 Firestore 中讀取所有的食材 (Ingredients)
//    func fetchIngredients(completion: @escaping ([Ingredient]?, Error?) -> Void) {
//        db.collection("ingredients").getDocuments { snapshot, error in
//            if let error = error {
//                completion(nil, error)
//            } else {
//                let ingredients = snapshot?.documents.compactMap { doc in
//                    do {
//                        return try doc.data(as: Ingredient.self)
//                    } catch {
//                        print("Error decoding ingredient: \(error.localizedDescription)")
//                        return nil
//                    }
//                }
//                completion(ingredients, nil)
//            }
//        }
//    }
//    
//    // 刪除食材
//    func deleteIngredient(_ ingredientId: String, completion: @escaping (Error?) -> Void) {
//        db.collection("ingredients").document(ingredientId).delete { error in
//            if let error = error {
//                print("Error deleting ingredient with ID \(ingredientId): \(error)")
//                completion(error)
//            } else {
//                print("Ingredient with ID \(ingredientId) deleted successfully.")
//                completion(nil)
//            }
//        }
//    }

    // 儲存食譜 (Recipe) 到 Firestore，使用 Result 來保持一致性
//    func saveRecipe(_ recipe: Recipe, completion: @escaping (Result<Void, Error>) -> Void) {
//        do {
//            if let id = recipe.id {
//                // 更新已存在的食譜
//                try db.collection("recipes").document(id).setData(from: recipe) { error in
//                    if let error = error {
//                        completion(.failure(error))
//                    } else {
//                        completion(.success(()))
//                    }
//                }
//            } else {
//                // 新增新的食譜
//                try db.collection("recipes").addDocument(from: recipe) { error in
//                    if let error = error {
//                        completion(.failure(error))
//                    } else {
//                        completion(.success(()))
//                    }
//                }
//            }
//        } catch let error {
//            completion(.failure(error))
//        }
//    }
//    
    // 從 Firestore 中讀取所有的食譜 (Recipes)
//    func fetchRecipes(completion: @escaping ([Recipe]?, Error?) -> Void) {
//        db.collection("recipes").getDocuments { snapshot, error in
//            if let error = error {
//                print("Error fetching recipes: \(error)")
//                completion(nil, error)
//            } else {
//                let recipes = snapshot?.documents.compactMap { doc in
//                    try? doc.data(as: Recipe.self)
//                }
//                completion(recipes, nil)
//            }
//        }
//    }
}

