//
//  RecipeListView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/15.
//

// RecipeListView.swift

import SwiftUI

struct RecipeListView: View {
    @EnvironmentObject var viewModel: RecipeSearchViewModel
    @Binding var selectedRecipe: Recipe?
    @Binding var searchText: String  // 接收搜索文字

    var body: some View {
        // 過濾 Favorite 並根據 searchText 進行篩選
        let filteredRecipes = viewModel.recipes.filter { $0.isFavorite && (searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText)) }
        
        // 顯示篩選後的食譜，若無資料則顯示範例食譜
        let displayedRecipes = filteredRecipes.isEmpty ? [RecipeCollectionView_Previews.sampleRecipe] : filteredRecipes


        ForEach(displayedRecipes.indices, id: \.self) { index in
            if displayedRecipes[index].id == RecipeCollectionView_Previews.sampleRecipe.id {
                // Add navigation for sampleRecipe
                Button(action: {
                    selectedRecipe = RecipeCollectionView_Previews.sampleRecipe
                }) {
                    RecipeCollectionView(recipe: RecipeCollectionView_Previews.sampleRecipe, toggleFavorite: {})
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                }
            } else {
                Button(action: {
                    selectedRecipe = displayedRecipes[index]
                }, label: {
                    RecipeCollectionView(recipe: displayedRecipes[index], toggleFavorite: {
                        // Find the original recipe in viewModel.recipes by ID and toggle favorite
                        if let recipeIndex = viewModel.recipes.firstIndex(where: { $0.id == displayedRecipes[index].id }) {
                            viewModel.toggleFavorite(for: viewModel.recipes[recipeIndex].id)
                        }
                    })
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                })
            }
        }
        .onAppear {
            print("Filtered Recipes: \(filteredRecipes)") // 這裡可以加上 print
        }
    }
}

struct RecipeListView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeListView(selectedRecipe: .constant(nil), searchText: .constant(""))
            .environmentObject(RecipeSearchViewModel())
    }
}
