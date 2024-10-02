//
//  DefaultRecipeView.swift
//  RecipeBookUI
//
//  Created by Eymen on 16.08.2023.
//

import SwiftUI

struct DefaultRecipeView: View {
    @ObservedObject var recipeManager: RecipeManager
    @State var selectedRecipe: DefaultRecipe? = nil
    var body: some View {
//        NavigationView {
            ScrollView {
                DefaultHorizontalScrolling(recipeManager: recipeManager)
                    .padding(.vertical)
                
                VStack {
                    ForEach(recipeManager.recipes) { recipe in
                        DefaultRecipeCard(recipe: recipe)
                            .onTapGesture {
                                selectedRecipe = recipe
                            }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .fullScreenCover(item: $selectedRecipe) { recipe in
                    DefaultRecipeDetailView(recipe: recipe)

                }
            }
            .background(.ultraThinMaterial)
//            .navigationTitle("Recipes")
        }
    }
//}

struct RecipeView_Previews: PreviewProvider {
    static var previews: some View {
        DefaultRecipeView(recipeManager: RecipeManager())
            .preferredColorScheme(.dark)
    }
}
