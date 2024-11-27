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
    @Published var errorMessage: ErrorMessage?
    
    var showAlertClosure: ((ActiveAlert) -> Void)?
    
    private let firestoreService: FirestoreService
    
    init(firestoreService: FirestoreService = FirestoreService()) {
        self.firestoreService = firestoreService
        
    }
    
    private let recipeService = RecipeSearchService()
    
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
            
            favoritesRef.document("\(recipeId)").delete { error in
                if let error = error {
                    print("Error removing favorite: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        self.recipes[index].isFavorite = false
                        
                        if self.selectedRecipe?.id == recipeId {
                            self.selectedRecipe?.isFavorite = false
                        }
                    }
                }
            }
        } else {
            
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
                        
                        if self.selectedRecipe?.id == recipeId {
                            self.selectedRecipe?.isFavorite = true
                        }
                    }
                }
            }
        }
    }
    
    func checkIfFavorite(recipeId: Int) {
        
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
                            dishTypes: dishTypes
                        )
                        favoriteRecipes.append(recipe)
                    }
                }
                DispatchQueue.main.async {
                    self.recipes = favoriteRecipes
                    print("Loaded favorites: \(self.recipes)")
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
    
    func addIngredientToCart(_ ingredient: ParsedIngredient, foodItemStore: FoodItemStore) -> Bool {
        guard let currentUser = Auth.auth().currentUser else {
            DispatchQueue.main.async {
                self.showAlertClosure?(.error(ErrorMessage(message: "An error occurred.")))
            }
            return false
        }
        
        if foodItemStore.foodItems.firstIndex(where: { $0.name.lowercased() == ingredient.name.lowercased() }) != nil {
            
            DispatchQueue.main.async {
                self.showAlertClosure?(.accumulation(ingredient))
            }
            return false
        } else {
            let newFoodItem = FoodItem(
                id: UUID().uuidString,
                name: ingredient.name,
                quantity: ingredient.quantity,
                unit: ingredient.unit,
                status: .toBuy,
                expirationDate: ingredient.expirationDate,
                imageURL: nil
            )
            
            DispatchQueue.main.async {
                foodItemStore.foodItems.append(newFoodItem)
                self.showAlertClosure?(.ingredient("\(ingredient.name) added to your Grocery List 🛒"))
            }
            
            firestoreService.addFoodItem(forUser: currentUser.uid, foodItem: newFoodItem, image: nil) { result in
                switch result {
                case .success:
                    print("Food item successfully added to Firestore.")
                case .failure(let error):
                    print("Failed to add food item to Firestore: \(error.localizedDescription)")
                }
            }
            return true
        }
    }
    
    func handleAccumulationChoice(for ingredient: ParsedIngredient, accumulate: Bool, foodItemStore: FoodItemStore) {
        guard let existingIndex = foodItemStore.foodItems.firstIndex(where: { $0.name.lowercased() == ingredient.name.lowercased() }) else {
            return
        }
        
        let existingItem = foodItemStore.foodItems[existingIndex]
        if accumulate {
            
            let newQuantity = existingItem.quantity + ingredient.quantity
            DispatchQueue.main.async {
                foodItemStore.foodItems[existingIndex].quantity = newQuantity
                self.showAlertClosure?(.ingredient("Updated quantity of \(ingredient.name) to \(newQuantity) \(ingredient.unit)."))
            }
            
            if let userId = Auth.auth().currentUser?.uid {
                let updatedFields: [String: Any] = ["quantity": newQuantity]
                firestoreService.updateFoodItem(forUser: userId, foodItemId: existingItem.id, updatedFields: updatedFields) { result in
                    if case .failure(let error) = result {
                        print("Failed to update food item in Firestore: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            
            DispatchQueue.main.async {
                self.showAlertClosure?(.regular(
                    title: "No Changes Made",
                    message: "\(ingredient.name) remains at \(existingItem.quantity) \(ingredient.unit)."
                ))
            }
        }
    }
    
    func adjustServings(newServings: Int) {
        guard var recipe = selectedRecipe, newServings > 0, recipe.servings > 0 else {
            if let recipe = selectedRecipe, recipe.servings <= 0 {
                errorMessage = ErrorMessage(message: "The original serving number is invalid.")
            } else {
                errorMessage = ErrorMessage(message: "Please enter the correct serving numbers.")
            }
            return
        }
        recipe.adjustIngredientAmounts(forNewServings: newServings)
        selectedRecipe = recipe
    }
    
    func getRecipeDetails(recipeId: Int) {
        
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
                    self?.checkIfFavorite(recipeId: recipeId)
                    details.isFavorite = self?.recipes.first(where: { $0.id == recipeId })?.isFavorite ?? false
                    self?.selectedRecipe = details
                case .failure(_):
                    self?.errorMessage = ErrorMessage(message: "Failed to fetch recipe details.")
                }
            }
        }
    }
}

