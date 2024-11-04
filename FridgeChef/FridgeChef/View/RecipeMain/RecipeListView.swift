//
//  RecipeListView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/15.
//

import SwiftUI

struct RecipeListView: View {
    @ObservedObject var viewModel: RecipeSearchViewModel
    @Binding var selectedRecipe: Recipe?
    @Binding var searchText: String
    
    var body: some View {
        
        let favoriteRecipes = viewModel.recipes.filter {
            $0.isFavorite && (searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText))
        }
        
        let displayedRecipes = favoriteRecipes.isEmpty ? [RecipeCollectionView_Previews.sampleRecipe] : favoriteRecipes
        
        VStack {
            ForEach(displayedRecipes.indices, id: \.self) { index in
                Button(action: {
                    selectedRecipe = displayedRecipes[index]
                }) {
                    RecipeCollectionView(
                        recipe: displayedRecipes[index],
                        toggleFavorite: {
                            if let recipeIndex = viewModel.recipes.firstIndex(where: { $0.id == displayedRecipes[index].id }) {
                                viewModel.toggleFavorite(for: viewModel.recipes[recipeIndex].id)
                            }
                        }
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

struct RecipeListView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeListView(viewModel: RecipeSearchViewModel(), selectedRecipe: .constant(nil), searchText: .constant(""))
    }
}
