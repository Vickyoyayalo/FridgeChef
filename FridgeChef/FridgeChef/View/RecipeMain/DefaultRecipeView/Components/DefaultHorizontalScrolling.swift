//
//  DefaultHorizontalScrolling.swift
//  RecipeBookUI
//
//  Created by Eymen on 16.08.2023.
//

import SwiftUI

struct DefaultHorizontalScrolling: View {
    @ObservedObject var recipeManager: RecipeManager
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(recipeManager.recipes.shuffled()) { recipe in
                    DefaultRecipeCard(recipe: recipe)
                }
                .padding(.horizontal)
            }
        }
    }
}
