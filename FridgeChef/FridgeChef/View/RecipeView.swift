//
//  RecipeView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/16.
//

import SwiftUI

struct RecipeView: View {
    @StateObject private var viewModel = RecipeViewModel()
    let ingredientId: String? // 可選的食材 ID 用於篩選食譜
    
    var body: some View {
        VStack {
            // 顯示錯誤信息（如果有）
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage).foregroundColor(.red)
            }
            
            // 顯示食譜列表
            List(viewModel.recipes) { recipe in
                VStack(alignment: .leading) {
                    Text(recipe.name)
                        .font(.headline)
                    Text("烹飪時間: \(recipe.cookingTime) 分鐘")
                    Text("份量: \(recipe.servings)")
                }
            }
        }
        .onAppear {
            // 當視圖顯示時，根據 ingredientId 獲取食譜
            viewModel.fetchRecipes(for: ingredientId)
        }
        .navigationTitle("推薦食譜")
    }
}
