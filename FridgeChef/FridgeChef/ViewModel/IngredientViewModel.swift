//
//  IngredientViewModel.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//

import SwiftUI
import FirebaseStorage

class IngredientViewModel: ObservableObject {
    private let firestoreService = FirestoreService()
    
    @Published var ingredients: [Ingredient] = [] // 儲存所有食材
    @Published var errorMessage: String? // 儲存錯誤訊息

    // 新增或更新食材
    func addIngredient(name: String, expirationDate: Date, ingredientPhoto: UIImage?, completion: @escaping (Bool) -> Void) {
        var ingredient = Ingredient(name: name, ingredientPhoto: [], expirationDate: expirationDate, category: [], storage: [])

        // 如果有照片，先處理照片上傳
        if let ingredientImage = ingredientPhoto, let imageData = ingredientImage.jpegData(compressionQuality: 0.8) {
            let storageRef = Storage.storage().reference(withPath: "ingredients/\(UUID().uuidString).jpg")
            storageRef.putData(imageData) { _, error in
                if let error = error {
                    self.errorMessage = "照片上傳失敗: \(error.localizedDescription)"
                    completion(false)
                    return
                }

                storageRef.downloadURL { url, error in
                    guard let downloadURL = url else {
                        self.errorMessage = "獲取照片URL失敗: \(error?.localizedDescription ?? "未知錯誤")"
                        completion(false)
                        return
                    }
                    ingredient.ingredientPhoto.append(downloadURL.absoluteString)
                    self.saveIngredientToFirestore(ingredient, completion: completion)
                }
            }
        } else {
            // 沒有照片的情況直接保存食材
            saveIngredientToFirestore(ingredient, completion: completion)
        }
    }
    
    // 從 FirestoreService 保存食材
    private func saveIngredientToFirestore(_ ingredient: Ingredient, completion: @escaping (Bool) -> Void) {
        firestoreService.saveIngredient(ingredient) { result in
            switch result {
            case .success:
                completion(true)
            case .failure(let error):
                self.errorMessage = "存儲食材失敗: \(error.localizedDescription)"
                completion(false)
            }
        }
    }

    // 獲取所有食材
    func fetchIngredients() {
        firestoreService.fetchIngredients { ingredients, error in
            if let error = error {
                self.errorMessage = "讀取食材失敗: \(error.localizedDescription)"
            } else if let ingredients = ingredients {
                self.ingredients = ingredients
            }
        }
    }
}
