//
//  RecipeView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//

import SwiftUI

struct RecipeView: View {
    @ObservedObject var recipeManager: RecipeManager
    @State private var searchText = ""
    @State var selectedRecipe: Recipe? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                HorizontalScrolling(recipeManager: recipeManager)
//                    .padding(.vertical)
                
                VStack {
                    // 在这里应用搜索逻辑
                    ForEach(recipeManager.recipes.filter { recipe in
                        searchText.isEmpty || recipe.title.lowercased().contains(searchText.lowercased())
                    }) { recipe in
                        SimpleRecipeCard(recipe: recipe)
                            .onTapGesture {
                                selectedRecipe = recipe
                            }
                            .padding()
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(.ultraThickMaterial)
                .fullScreenCover(item: $selectedRecipe) { recipe in
                    RecipeDetailView(recipe: recipe)
                        .preferredColorScheme(.light)
                }
            }
            .background(.ultraThinMaterial)
            .navigationTitle("My Favorite Recipe")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Recipes")
        }
    }

}

struct RecipeView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeView(recipeManager: RecipeManager())
            .preferredColorScheme(.light)
    }
}
