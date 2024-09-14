//
//  FirestoreService.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/13.
//

import FirebaseFirestore

// FirestoreService: 用來處理與 Firestore 資料庫相關的操作
class FirestoreService {
    private let db = FirebaseManager.shared.firestore
    
    // 儲存食材 (Ingredient) 到 Firestore
    func saveIngredient(_ ingredient: Ingredient, completion: @escaping (Error?) -> Void) {
        do {
            if let id = ingredient.id {
                // 如果有 ID，則更新資料
                try db.collection("ingredients").document(id).setData(from: ingredient, completion: completion)
            } else {
                // 沒有 ID 則新增資料並自動生成文檔 ID
                try db.collection("ingredients").addDocument(from: ingredient, completion: completion)
            }
        } catch let error {
            print("Error writing ingredient to Firestore: \(error)")
            completion(error)
        }
    }
    
    // 從 Firestore 中讀取所有的食材 (Ingredients)
    func fetchIngredients(completion: @escaping ([Ingredient]?, Error?) -> Void) {
        db.collection("ingredients").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching ingredients: \(error)")
                completion(nil, error)
            } else {
                let ingredients = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Ingredient.self)
                }
                completion(ingredients, nil)
            }
        }
    }
    
    // 刪除食材
    func deleteIngredient(_ ingredientId: String, completion: @escaping (Error?) -> Void) {
        db.collection("ingredients").document(ingredientId).delete { error in
            if let error = error {
                print("Error deleting ingredient: \(error)")
                completion(error)
            } else {
                print("Ingredient deleted successfully.")
                completion(nil)
            }
        }
    }
    
    // 儲存食譜 (Recipe) 到 Firestore
    func saveRecipe(_ recipe: Recipe, completion: @escaping (Error?) -> Void) {
        do {
            if let id = recipe.id {
                try db.collection("recipes").document(id).setData(from: recipe, completion: completion)
            } else {
                try db.collection("recipes").addDocument(from: recipe, completion: completion)
            }
        } catch let error {
            print("Error writing recipe to Firestore: \(error)")
            completion(error)
        }
    }
    
    // 從 Firestore 中讀取所有的食譜 (Recipes)
    func fetchRecipes(completion: @escaping ([Recipe]?, Error?) -> Void) {
        db.collection("recipes").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching recipes: \(error)")
                completion(nil, error)
            } else {
                let recipes = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: Recipe.self)
                }
                completion(recipes, nil)
            }
        }
    }
}

