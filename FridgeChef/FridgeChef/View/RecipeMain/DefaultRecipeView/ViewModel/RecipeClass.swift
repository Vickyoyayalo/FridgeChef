//
//  DefaultRecipeClass.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/06.
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
               instructions: "1. Start by preheating your oven to its highest temperature.\n2. Roll out the pizza dough into your desired shape.\n3. Spread a thin layer of crushed tomatoes over the dough, leaving a border around the edges.\n4. Tear the fresh mozzarella into small pieces and distribute them evenly over the tomatoes. Sprinkle fresh basil leaves on top. ",
               imageName: "confessional"),
        
        DefaultRecipe(title: "Grilled Chicken Salad", headline: "Lunch",
               ingredients: ["Chicken breasts", "Mixed greens", "Cherry tomatoes", "Cucumbers"],
               instructions: "1. Start by grilling the chicken breasts until they are cooked through and have nice grill marks. \n2.While the chicken is cooking, prepare the salad by washing and drying the mixed greens, slicing the cherry tomatoes, and chopping the cucumbers.\n3. Once the chicken is done, let it rest for a few minutes before slicing it.\n4. In a large bowl, toss the greens, tomatoes, and cucumbers together. ",
               imageName: "graham"),
        
        DefaultRecipe(title: "Vegetable Stir-Fry", headline: "Dinner",
               ingredients: ["Assorted vegetables", "Tofu", "Soy sauce", "Ginger", "Garlic", "Sesame oil"],
               instructions: "1. Start by preparing the vegetables. Wash and chop them into bite-sized pieces.\n2. Press the tofu to remove excess moisture and cut it into cubes.\n3. In a wok or large skillet, heat some sesame oil over medium-high heat.\n4. Add ginger and garlic, sautéing until fragrant. ",
               imageName: "LoginDetailImage"),
        
        DefaultRecipe(title: "Baked Shrimp sluna", headline: "Dinner",
               ingredients: ["Salmon fillets", "Lemon", "Dill", "Garlic", "Olive oil"],
               instructions: "1. Preheat your oven to 375°F (190°C). Place the salmon fillets on a baking sheet lined with parchment paper.\n2. Drizzle olive oil over the fillets and rub them with minced garlic and chopped dill. \n3.Thinly slice the lemon and place lemon slices on top of the salmon.",
               imageName: "traif"),
        
        DefaultRecipe(title: "Homestyle Beef Stew", headline: "Dinner",
               ingredients: ["Beef stew meat", "Potatoes", "Carrots", "Onions", "Beef broth", "Thyme"],
               instructions: "1. Start by cutting the beef stew meat into bite-sized pieces and seasoning them with salt and pepper.\n2. Heat some oil in a large pot over medium-high heat.\n3. Brown the beef pieces on all sides, then remove them from the pot.\n4. In the same pot, add chopped onions and sauté until they're translucent.\n5. Add diced carrots and potatoes, and stir for a few minutes. Return the browned beef to the pot. ",
               imageName: "donostia"),
        
        DefaultRecipe(title: "Caprese Salad", headline: "Breakfast",
               ingredients: ["Tomatoes", "Fresh mozzarella", "Basil", "Balsamic glaze", "Olive oil"],
               instructions: "1. Slice the tomatoes and fresh mozzarella into rounds of similar thickness.\n2. Arrange the tomato and mozzarella slices on a serving plate, alternating and slightly overlapping them.\n3. Tuck fresh basil leaves between the tomato and mozzarella slices. ",
               imageName: "forkee"),
    ]
}
//import Foundation
//
//struct RecipeManager {
//    // 示例推薦食譜
//    let recommendedRecipes: [Recipe] = [
//        Recipe(id: 1, title: "意大利面", image: "italianPasta", servings: 4, readyInMinutes: 30, summary: "美味的意大利面食譜。", dishTypes: ["主菜"]),
//        Recipe(id: 2, title: "法式吐司", image: "frenchToast", servings: 2, readyInMinutes: 15, summary: "香甜的法式吐司。", dishTypes: ["早餐"]),
//        // 添加更多推薦食譜
//    ]
//    
//    // 示例分類
//    let categories: [String] = ["Breakfast", "Lunch", "Dinner", "Dessert", "Brunch"]
//    
//    // 示例熱門搜索
//    let popularSearches: [String] = ["Chicken", "Beef", "Gluten free", "Italian"]
//    
//    // 示例食譜（用於搜尋記錄為空時）
//    let sampleRecipe: Recipe = Recipe(
//        id: 999,
//        title: "Find more Favorite Recipe!",
//        image: nil,
//        servings: 2,
//        readyInMinutes: 15,
//        summary: "Get more Favorites.",
//        isFavorite: false,
//        dishTypes: ["Breakfast"]
//    )
//}
