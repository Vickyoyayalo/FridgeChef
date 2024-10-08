//
//  DefaultRecipeCard.swift
//  RecipeBookUI
//
//  Created by Eymen on 16.08.2023.
//

import SwiftUI

struct DefaultRecipeCard: View {
    var recipe: DefaultRecipe
    var body: some View {
        VStack(alignment: .leading) {
            VStack {
                Image(recipe.imageName)
                    .resizable()
                    .scaledToFill()
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y:4)
            }
            .frame(maxWidth: .infinity, maxHeight: 200)
            .background(.white.opacity(0.5))
            .cornerRadius(15)
            
            VStack(alignment: .leading, spacing: 7) {
                Text(recipe.headline)
                    .foregroundColor(Color(UIColor(named: "SecondaryColor") ?? UIColor.blue))
                    .font(.custom("ArialRoundedMTBold", size: 15))
                
                Text(recipe.title)
                    .font(.custom("ArialRoundedMTBold", size: 20))
                
                Text(recipe.ingredients.joined(separator: ", "))
                    .font(.custom("ArialRoundedMTBold", size: 15))
                    .foregroundColor(.gray)
                    .lineLimit(nil)
                    .frame(width: 300, height: 40, alignment: .topLeading)
            }
        }
    }
}

struct RecipeCard_Previews: PreviewProvider {
    static var previews: some View {
        DefaultRecipeCard(recipe: DefaultRecipe(title: "Vegetable Stir-Fry", headline: "Dinner",
                                  ingredients: ["Assorted vegetables", "Tofu", "Soy sauce", "Ginger", "Garlic", "Sesame oil"],
                                  instructions: "Start by preparing the vegetables. Wash and chop them into bite-sized pieces. Press the tofu to remove excess moisture and cut it into cubes. In a wok or large skillet, heat some sesame oil over medium-high heat. Add ginger and garlic, sautéing until fragrant. Add the tofu and stir-fry until it's golden and slightly crispy.",
                                  imageName: "forkee"))
        .preferredColorScheme(.light)
    }
}
