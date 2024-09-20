//
//  RecipeCard.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/18.
//

import SwiftUI

struct SimpleRecipeCard: View {
    var recipe: Recipe
    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                Image(recipe.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding()
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x:0, y: 4)
            }
            .frame(maxWidth: .infinity, maxHeight: 200)
            .background(.ultraThinMaterial)
            .cornerRadius(15)
            
            VStack(alignment: .leading, spacing: 7) {
                Text(recipe.headline)
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text(recipe.title)
                    .font(.title3).bold()
                
                Text(recipe.ingredients.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(width: 300, height: 40, alignment: .topLeading)
            }
        }
    }
}

struct RecipeCard_Previews: PreviewProvider {
    static var previews: some View {
        SimpleRecipeCard(recipe: Recipe(title: "Vegetable Stir-Fry", headline: "Dinner",
                                  ingredients: ["Assorted vegetables", "Tofu", "Soy sauce", "Ginger", "Garlic", "Sesame oil"],
                                  instructions: "Start by preparing the vegetables. Wash and chop them into bite-sized pieces. Press the tofu to remove excess moisture and cut it into cubes. In a wok or large skillet, heat some sesame oil over medium-high heat. Add ginger and garlic, sautéing until fragrant. Add the tofu and stir-fry until it's golden and slightly crispy. Add the chopped vegetables",
                                  imageName: "cask"))
        .preferredColorScheme(.light)
    }
}

