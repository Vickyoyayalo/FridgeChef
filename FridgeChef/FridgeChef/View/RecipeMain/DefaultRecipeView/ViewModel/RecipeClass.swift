//
//  DefaultRecipeClass.swift
//  RecipeBookUI
//
//  Created by Eymen on 16.08.2023.
//

import Foundation


struct DefaultRecipe: Identifiable {
    var id = UUID()
    var title: String
    var headline: String
    var ingredients: [String]
    var instructions: String
    var imageName: String
}


class RecipeManager:  ObservableObject {
    @Published var recipes: [DefaultRecipe] = [
        DefaultRecipe(title: "Classic Margherita Pizza", headline: "Lunch",
               ingredients: ["Pizza dough", "Tomatoes", "Fresh mozzarella", "Basil", "Olive oil"],
               instructions: "Start by preheating your oven to its highest temperature. Roll out the pizza dough into your desired shape. Spread a thin layer of crushed tomatoes over the dough, leaving a border around the edges. Tear the fresh mozzarella into small pieces and distribute them evenly over the tomatoes. Sprinkle fresh basil leaves on top. ",
               imageName: "pizza"),
        
        DefaultRecipe(title: "Grilled Chicken Salad", headline: "Lunch",
               ingredients: ["Chicken breasts", "Mixed greens", "Cherry tomatoes", "Cucumbers", "Balsamic vinaigrette"],
               instructions: "Start by grilling the chicken breasts until they are cooked through and have nice grill marks. While the chicken is cooking, prepare the salad by washing and drying the mixed greens, slicing the cherry tomatoes, and chopping the cucumbers. Once the chicken is done, let it rest for a few minutes before slicing it. In a large bowl, toss the greens, tomatoes, and cucumbers together. ",
               imageName: "chicken"),
        
        DefaultRecipe(title: "Vegetable Stir-Fry", headline: "Dinner",
               ingredients: ["Assorted vegetables", "Tofu", "Soy sauce", "Ginger", "Garlic", "Sesame oil"],
               instructions: "Start by preparing the vegetables. Wash and chop them into bite-sized pieces. Press the tofu to remove excess moisture and cut it into cubes. In a wok or large skillet, heat some sesame oil over medium-high heat. Add ginger and garlic, sautéing until fragrant. ",
               imageName: "stir_fry"),
        
        DefaultRecipe(title: "Baked Salmon", headline: "Dinner",
               ingredients: ["Salmon fillets", "Lemon", "Dill", "Garlic", "Olive oil"],
               instructions: "Preheat your oven to 375°F (190°C). Place the salmon fillets on a baking sheet lined with parchment paper. Drizzle olive oil over the fillets and rub them with minced garlic and chopped dill. Thinly slice the lemon and place lemon slices on top of the salmon.",
               imageName: "salmon"),
        
        DefaultRecipe(title: "Homestyle Beef Stew", headline: "Dinner",
               ingredients: ["Beef stew meat", "Potatoes", "Carrots", "Onions", "Beef broth", "Thyme"],
               instructions: "Start by cutting the beef stew meat into bite-sized pieces and seasoning them with salt and pepper. Heat some oil in a large pot over medium-high heat. Brown the beef pieces on all sides, then remove them from the pot. In the same pot, add chopped onions and sauté until they're translucent. Add diced carrots and potatoes, and stir for a few minutes. Return the browned beef to the pot. ",
               imageName: "beef"),
        
        DefaultRecipe(title: "Caprese Salad", headline: "Lunch",
               ingredients: ["Tomatoes", "Fresh mozzarella", "Basil", "Balsamic glaze", "Olive oil"],
               instructions: "Slice the tomatoes and fresh mozzarella into rounds of similar thickness. Arrange the tomato and mozzarella slices on a serving plate, alternating and slightly overlapping them. Tuck fresh basil leaves between the tomato and mozzarella slices. ",
               imageName: "salad"),
    ]
}
