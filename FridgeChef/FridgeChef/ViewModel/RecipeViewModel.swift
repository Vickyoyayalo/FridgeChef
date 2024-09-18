//
//  RecipeViewModel.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//

//import SwiftUI
//
//class RecipeViewModel: ObservableObject {
//    @Published var recipes: [Recipe] = [] // 儲存所有食譜
//    @Published var errorMessage: String? // 儲存錯誤訊息
//    private let firestoreService = FirestoreService()
//    
//    // 獲取所有食譜，或根據某個食材來篩選
//    func fetchRecipes(for ingredientId: String?) {
//        firestoreService.fetchRecipes { recipes, error in
//            if let error = error {
//                self.errorMessage = "讀取食譜失敗: \(error.localizedDescription)"
//                return
//            }
//
//            // 如果有 ingredientId，篩選出匹配的食譜
//            if let ingredientId = ingredientId {
//                self.recipes = recipes?.filter { $0.ingredientId == ingredientId } ?? []
//            } else {
//                self.recipes = recipes ?? []
//            }
//        }
//    }
//}
//
//
