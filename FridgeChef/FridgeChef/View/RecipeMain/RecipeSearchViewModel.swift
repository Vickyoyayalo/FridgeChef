//
//  RecipeSearchViewModel.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/28.


import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

// MARK: - ErrorMessage Struct
struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

// MARK: - ViewModel
class RecipeSearchViewModel: ObservableObject {
    private let db = Firestore.firestore()
    @Published var recipes: [Recipe] = []
    @Published var selectedRecipe: RecipeDetails?
    @Published var isLoading: Bool = false
    @Published var errorMessage: ErrorMessage?  // 修改為 ErrorMessage?
    
    private let recipeService = RecipeSearchService()

    
    // 提取收藏食譜的ID
    private func getSavedFavoriteIDs() -> Set<Int> {
        if let savedFavorites = UserDefaults.standard.data(forKey: "favorites"),
           let loadedFavorites = try? JSONDecoder().decode([Recipe].self, from: savedFavorites) {
            return Set(loadedFavorites.map { $0.id })
        }
        return Set()
    }
    
    func searchRecipes(query: String, maxFat: Int? = nil) {
        guard !query.isEmpty else {
            errorMessage = ErrorMessage(message: "Search bar is empty 🥹")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        recipeService.searchRecipes(query: query, maxFat: maxFat) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let response):
                    let favoriteIDs = self?.getSavedFavoriteIDs() ?? []
                    self?.recipes = response.results.map { recipe in
                        var mutableRecipe = recipe
                        if favoriteIDs.contains(recipe.id) {
                            mutableRecipe.isFavorite = true
                        }
                        return mutableRecipe
                    }
                case .failure(let error):
                    self?.errorMessage = ErrorMessage(message: error.localizedDescription)
                }
            }
        }
    }
    
    func toggleFavorite(for recipeId: Int) {
        guard let index = recipes.firstIndex(where: { $0.id == recipeId }) else { return }

        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No user is currently logged in.")
            return
        }

        let favoritesRef = db.collection("users").document(userId).collection("favorites")

        if recipes[index].isFavorite {
            // 從 Firestore 移除收藏
            favoritesRef.document("\(recipeId)").delete { error in
                if let error = error {
                    print("Error removing favorite: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self.recipes[index].isFavorite = false
                        // 同步更新 selectedRecipe
                        if self.selectedRecipe?.id == recipeId {
                            self.selectedRecipe?.isFavorite = false
                        }
                    }
                }
            }
        } else {
            // 添加到 Firestore 收藏，並包含 dishTypes
            let favoriteData: [String: Any] = [
                "id": recipeId,
                "title": recipes[index].title,
                "image": recipes[index].image ?? "",
                "servings": recipes[index].servings,
                "readyInMinutes": recipes[index].readyInMinutes,
                "dishTypes": recipes[index].dishTypes // 添加 dishTypes
            ]

            favoritesRef.document("\(recipeId)").setData(favoriteData) { error in
                if let error = error {
                    print("Error saving favorite: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self.recipes[index].isFavorite = true
                        // 同步更新 selectedRecipe
                        if self.selectedRecipe?.id == recipeId {
                            self.selectedRecipe?.isFavorite = true
                        }
                    }
                }
            }
        }
    }

    // 方法：檢查該食譜是否已收藏
    func checkIfFavorite(recipeId: Int) {
        // 確保已經有使用者登入
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No user is currently logged in.")
            return
        }

        let favoritesRef = db.collection("users").document(userId).collection("favorites")

        favoritesRef.document("\(recipeId)").getDocument { document, error in
            if let document = document, document.exists {
                DispatchQueue.main.async {
                    self.selectedRecipe?.isFavorite = true
                }
            } else {
                DispatchQueue.main.async {
                    self.selectedRecipe?.isFavorite = false
                }
            }
        }
    }
    
    func loadFavorites() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No user is currently logged in.")
            return
        }

        let favoritesRef = db.collection("users").document(userId).collection("favorites")
        favoritesRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching favorites: \(error.localizedDescription)")
                return
            }

            if let snapshot = snapshot {
                var favoriteRecipes: [Recipe] = []
                for document in snapshot.documents {
                    let favoriteData = document.data()
                    if let recipeId = favoriteData["id"] as? Int,
                       let title = favoriteData["title"] as? String,
                       let image = favoriteData["image"] as? String,
                       let readyInMinutes = favoriteData["readyInMinutes"] as? Int,
                       let servings = favoriteData["servings"] as? Int {

                        let dishTypes = favoriteData["dishTypes"] as? [String] ?? []

                        let recipe = Recipe(
                            id: recipeId,
                            title: title,
                            image: image,
                            servings: servings,
                            readyInMinutes: readyInMinutes,
                            summary: "",
                            isFavorite: true,
                            dishTypes: dishTypes // 設置 dishTypes
                        )
                        favoriteRecipes.append(recipe)
                    }
                }
                DispatchQueue.main.async {
                    self.recipes = favoriteRecipes
                    print("Loaded favorites: \(self.recipes)")  // 這裡加上 print
                }
            }
        }
    }
private func saveFavorites() {
    let favorites = recipes.filter { $0.isFavorite }
    if let encoded = try? JSONEncoder().encode(favorites) {
        UserDefaults.standard.set(encoded, forKey: "favorites")
    }
}

    func adjustServings(newServings: Int) {
        guard var recipe = selectedRecipe, newServings > 0, recipe.servings > 0 else {
            if let recipe = selectedRecipe, recipe.servings <= 0 {
                errorMessage = ErrorMessage(message: "原始份量無效。")
            } else {
                errorMessage = ErrorMessage(message: "請輸入有效的份量。")
            }
            return
        }
        recipe.adjustIngredientAmounts(forNewServings: newServings)
        selectedRecipe = recipe // 更新視圖
    }
    
    func getRecipeDetails(recipeId: Int) {
        // 開始加載
        isLoading = true
        errorMessage = nil

        recipeService.getRecipeInformation(recipeId: recipeId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false

                switch result {
                case .success(var details):
                    if details.servings <= 0 {
                        details.servings = 1
                    }
                    // 檢查是否已收藏
                    self?.checkIfFavorite(recipeId: recipeId)
                    details.isFavorite = self?.recipes.first(where: { $0.id == recipeId })?.isFavorite ?? false
                    self?.selectedRecipe = details  // 觸發視圖更新
                case .failure(let error):
                    self?.errorMessage = ErrorMessage(message: "Failed to fetch recipe details.")
                }
            }
        }
    }
}
