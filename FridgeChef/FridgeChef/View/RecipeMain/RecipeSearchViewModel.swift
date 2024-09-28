//
//  RecipeSearchViewModel.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/28.
//

import Foundation
import SwiftUI

// MARK: - ErrorMessage Struct
struct ErrorMessage: Identifiable {
    let id = UUID()
    let message: String
}

// MARK: - ViewModel
class RecipeSearchViewModel: ObservableObject {
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
            errorMessage = ErrorMessage(message: "搜尋關鍵字不能為空。")
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
        if let index = recipes.firstIndex(where: { $0.id == recipeId }) {
            recipes[index].isFavorite.toggle()
            saveFavorites()
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
    
//    func getRecipeDetails(recipeId: Int) {
//        isLoading = true
//        errorMessage = nil
//        
//        recipeService.getRecipeInformation(recipeId: recipeId) { [weak self] result in
//            DispatchQueue.main.async {
//                self?.isLoading = false
//                switch result {
//                case .success(var details):
//                    // 设置收藏状态
//                    details.isFavorite = self?.getSavedFavoriteIDs().contains(details.id) ?? false
//                    if details.servings <= 0 {
//                        print("Warning: Received servings <= 0 from API. Setting to 1.")
//                        details.servings = 1
//                    }
//                    self?.selectedRecipe = details
//
//                case .failure(let error):
//                    self?.errorMessage = ErrorMessage(message: error.localizedDescription)
//                }
//            }
//        }
//    }
    func getRecipeDetails(recipeId: Int) {
        // Start by setting isLoading to true to indicate that data fetching has begun
        isLoading = true
        // Clear any existing error messages to ensure fresh state for new data fetch
        errorMessage = nil

        // Call your recipe service to fetch recipe details by ID
        recipeService.getRecipeInformation(recipeId: recipeId) { [weak self] result in
            DispatchQueue.main.async {
                // Ensure that operations on completion are executed on the main thread
                self?.isLoading = false  // Stop the loading indicator once the fetch is complete or fails

                switch result {
                case .success(var details):
                    // Check and correct data integrity issues, e.g., servings shouldn't be 0 or negative
                    if details.servings <= 0 {
                        print("Warning: Received servings <= 0 from API. Setting to 1.")
                        details.servings = 1  // Default to 1 to avoid potential division by zero errors elsewhere
                    }

                    // Determine if the fetched recipe is already favorited by the user
                    details.isFavorite = self?.getSavedFavoriteIDs().contains(details.id) ?? false

                    // Update the state with the fetched recipe details
                    self?.selectedRecipe = details

                case .failure(let error):
                    // Handle errors such as network issues, decoding failures, etc.
                    print("Error fetching recipe details: \(error.localizedDescription)")
                    self?.errorMessage = ErrorMessage(message: "Failed to fetch recipe details. Please try again.")
                }
            }
        }
    }

}

