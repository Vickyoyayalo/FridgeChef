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
        
        let filteredRecipes = viewModel.recipes.filter { $0.isFavorite && (searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText)) }
        
        let displayedRecipes = filteredRecipes.isEmpty ? [RecipeCollectionView_Previews.sampleRecipe] : filteredRecipes


        ForEach(displayedRecipes.indices, id: \.self) { index in
            if displayedRecipes[index].id == RecipeCollectionView_Previews.sampleRecipe.id {
                
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
            print("Filtered Recipes: \(filteredRecipes)")
        }
    }
}

struct RecipeListView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeListView(
            viewModel: RecipeSearchViewModel(),
            selectedRecipe: .constant(nil),
            searchText: .constant(""))
    }
}
