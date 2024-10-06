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
        // 在 recipes 中找到对应的 recipe，并切换收藏状态
        if let index = recipes.firstIndex(where: { $0.id == recipeId }) {
            recipes[index].isFavorite.toggle()  // 切换收藏状态
            saveFavorites()  // 保存收藏状态到 UserDefaults

            // 同步更新 selectedRecipe 的收藏状态（如果当前详情页显示的食谱是该食谱）
            if selectedRecipe?.id == recipeId {
                selectedRecipe?.isFavorite = recipes[index].isFavorite
            }
        }
        
        objectWillChange.send()  // 手动触发视图更新
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
        // 开始加载
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
                    details.isFavorite = self?.getSavedFavoriteIDs().contains(details.id) ?? false
                    self?.selectedRecipe = details  // 触发视图更新
                case .failure(let error):
                    self?.errorMessage = ErrorMessage(message: "Failed to fetch recipe details.")
                }
            }
        }
    }
}
//import Foundation
//import SwiftUI
//
//// MARK: - ErrorMessage Struct
//struct ErrorMessage: Identifiable {
//    let id = UUID()
//    let message: String
//}
//
//// MARK: - ViewModel
//class RecipeSearchViewModel: ObservableObject {
//    @Published var recipes: [Recipe] = []
//    @Published var selectedRecipe: RecipeDetails?
//    @Published var isLoading: Bool = false
//    @Published var errorMessage: ErrorMessage?  // 修改為 ErrorMessage?
//    @Published var searchRecords: [Recipe] = []
//    
//    private let recipeService = RecipeSearchService()
//    private let searchRecordsKey = "searchRecords"// UserDefaults key
//    
//    init() {
//            loadSearchRecords() // 初始化時加載搜尋記錄
//        }
//    
//    // 提取收藏食譜的ID
//    private func getSavedFavoriteIDs() -> Set<Int> {
//        if let savedFavorites = UserDefaults.standard.data(forKey: "favorites"),
//           let loadedFavorites = try? JSONDecoder().decode([Recipe].self, from: savedFavorites) {
//            return Set(loadedFavorites.map { $0.id })
//        }
//        return Set()
//    }
//    
//    func searchRecipes(query: String, maxFat: Int? = nil) {
//        guard !query.isEmpty else {
//            errorMessage = ErrorMessage(message: "Keyword cannot be an empty value.")
//            return
//        }
//        
//        isLoading = true
//        errorMessage = nil
//        
//        recipeService.searchRecipes(query: query, maxFat: maxFat) { [weak self] result in
//            DispatchQueue.main.async {
//                self?.isLoading = false
//                switch result {
//                case .success(let response):
//                    let favoriteIDs = self?.getSavedFavoriteIDs() ?? []
//                    self?.recipes = response.results.map { recipe in
//                        var mutableRecipe = recipe
//                        if favoriteIDs.contains(recipe.id) {
//                            mutableRecipe.isFavorite = true
//                        }
//                        return mutableRecipe
//                    }
//                case .failure(let error):
//                    self?.errorMessage = ErrorMessage(message: error.localizedDescription)
//                }
//            }
//        }
//    }
//    
//    func searchRecipesByCategory(category: String) {
//            guard !category.isEmpty else {
//                errorMessage = ErrorMessage(message: "Category cannot be an empty value.")
//                return
//            }
//            
//            isLoading = true
//            errorMessage = nil
//            
//            recipeService.searchRecipesByCategory(category: category) { [weak self] result in
//                DispatchQueue.main.async {
//                    self?.isLoading = false
//                    switch result {
//                    case .success(let response):
//                        let favoriteIDs = self?.getSavedFavoriteIDs() ?? []
//                        self?.recipes = response.results.map { recipe in
//                            var mutableRecipe = recipe
//                            if favoriteIDs.contains(recipe.id) {
//                                mutableRecipe.isFavorite = true
//                            }
//                            return mutableRecipe
//                        }
//                    case .failure(let error):
//                        self?.errorMessage = ErrorMessage(message: error.localizedDescription)
//                    }
//                }
//            }
//        }
//        
//    
//    func toggleFavorite(for recipeId: Int) {
//        // 在 recipes 中找到对应的 recipe，并切换收藏状态
//        if let index = recipes.firstIndex(where: { $0.id == recipeId }) {
//            recipes[index].isFavorite.toggle()  // 切换收藏状态
//            saveFavorites()  // 保存收藏状态到 UserDefaults
//
//            // 同步更新 selectedRecipe 的收藏状态（如果当前详情页显示的食谱是该食谱）
//            if selectedRecipe?.id == recipeId {
//                selectedRecipe?.isFavorite = recipes[index].isFavorite
//            }
//        }
//        
//        objectWillChange.send()  // 手动触发视图更新
//    }
//
//    private func saveFavorites() {
//        let favorites = recipes.filter { $0.isFavorite }
//        if let encoded = try? JSONEncoder().encode(favorites) {
//            UserDefaults.standard.set(encoded, forKey: "favorites")
//        }
//    }
//    
//    func adjustServings(newServings: Int) {
//        guard var recipe = selectedRecipe, newServings > 0, recipe.servings > 0 else {
//            if let recipe = selectedRecipe, recipe.servings <= 0 {
//                errorMessage = ErrorMessage(message: "原始份量無效。")
//            } else {
//                errorMessage = ErrorMessage(message: "請輸入有效的份量。")
//            }
//            return
//        }
//        recipe.adjustIngredientAmounts(forNewServings: newServings)
//        selectedRecipe = recipe // 更新視圖
//    }
//    
//    func getRecipeDetails(recipeId: Int) {
//        // 开始加载
//        isLoading = true
//        errorMessage = nil
//        
//        recipeService.getRecipeInformation(recipeId: recipeId) { [weak self] result in
//            DispatchQueue.main.async {
//                self?.isLoading = false
//                
//                switch result {
//                case .success(var details):
//                    if details.servings <= 0 {
//                        details.servings = 1
//                    }
//                    details.isFavorite = self?.getSavedFavoriteIDs().contains(details.id) ?? false
//                    self?.selectedRecipe = details  // 触发视图更新
//                case .failure(let error):
//                    self?.errorMessage = ErrorMessage(message: "Failed to fetch recipe details.")
//                }
//            }
//        }
//    }
//    // MARK: - 搜尋記錄管理
//        
//        func addSearchRecord(recipe: Recipe) {
//            // 移除已存在的相同食譜
//            searchRecords.removeAll { $0.id == recipe.id }
//            // 插入到最前面
//            searchRecords.insert(recipe, at: 0)
//            // 保留五筆記錄
//            if searchRecords.count > 5 {
//                searchRecords = Array(searchRecords.prefix(5))
//            }
//            saveSearchRecords()
//        }
//        
//        func loadSearchRecords() {
//            if let savedRecords = UserDefaults.standard.data(forKey: searchRecordsKey),
//               let decodedRecords = try? JSONDecoder().decode([Recipe].self, from: savedRecords) {
//                searchRecords = decodedRecords
//            } else {
//                searchRecords = [] // 或者初始化為空數組
//            }
//        }
//        
//        func saveSearchRecords() {
//            if let encoded = try? JSONEncoder().encode(searchRecords) {
//                UserDefaults.standard.set(encoded, forKey: searchRecordsKey)
//            }
//        }
//    
//}

