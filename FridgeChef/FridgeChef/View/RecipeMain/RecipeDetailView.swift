//
//  RecipeDetailView.swift
//  WhatToEat
//
//  Created by Vickyhereiam on 2024/9/27.
//

import SwiftUI

struct RecipeDetailView: View {
    @EnvironmentObject var viewModel: RecipeSearchViewModel
    @State private var inputServings: String = ""
    let recipeId: Int

    @State private var ratingScore: Int = 5
    @State private var commentUser: String = ""
    @State private var commentText: String = ""

    // 定義主要色調
    let primaryColor = Color(UIColor(named: "NavigationBarTitle") ?? .orange)
    let secondaryColor = Color.white
    let backgroundColor = Color(.systemGray6)
    let tagColor = Color(UIColor(named: "SecondaryColor") ?? .black)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let recipe = viewModel.selectedRecipe {
                    ZStack(alignment: .topTrailing) {
                        if let imageUrl = recipe.image {
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 250)
                                    .cornerRadius(15)
                                    .shadow(radius: 10)
                            } placeholder: {
                                ProgressView()
                                    .frame(height: 250)
                            }
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFill()
                                .frame(height: 250)
                                .cornerRadius(15)
                                .shadow(radius: 5)
                                .foregroundColor(.gray)
                                .background(Color(.systemGray5))
                        }

                        Button(action: {
                            viewModel.toggleFavorite(for: recipeId)
                        }) {
                            Image(systemName: recipe.isFavorite == true ? "heart.fill" : "heart")
                                .foregroundColor(recipe.isFavorite == true ? primaryColor : secondaryColor)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                                .shadow(radius: 5)
                                .padding()
                        }
                    }
                    .frame(height: 250)

                    // 食譜標題
                    Text(recipe.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(primaryColor)
                        .padding(.horizontal)
                        .fixedSize(horizontal: false, vertical: true)

                    // 基本資訊
                    HStack {
                        Label("\(recipe.servings) 份", systemImage: "person.2")
                        Spacer()
                        Label("\(recipe.readyInMinutes) 分鐘", systemImage: "clock")
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                    // 調整份量
                    SectionView(title: "調整份量") {
                        HStack {
                            TextField("份量", text: $inputServings, onCommit: {
                                updateServings()
                            })
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                            Button(action: {
                                updateServings()
                            }) {
                                Text("更新")
                                    .bold()
                                    .foregroundColor(.white)
                                    .padding(5)
                                    .background(primaryColor)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // 菜系、類型和飲食
                    if !recipe.cuisines.isEmpty || !recipe.dishTypes.isEmpty || !recipe.diets.isEmpty {
                        SectionView(title: "分類") {
                            VStack(alignment: .leading, spacing: 5) { // 減少間距
                                if !recipe.cuisines.isEmpty {
                                    CategorySectionView(title: "• 菜系", items: recipe.cuisines)
                                }
                                if !recipe.dishTypes.isEmpty {
                                    CategorySectionView(title: "• 類型", items: recipe.dishTypes)
                                }
                                if !recipe.diets.isEmpty {
                                    CategorySectionView(title: "• 飲食", items: recipe.diets)
                                }
                            }
                            .padding(.leading, 20)
                        }
                    }

                    // 食材
                    SectionView(title: "食材") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(recipe.extendedIngredients) { ingredient in
                                HStack(alignment: .top) {
                                    Text("•")
                                        .font(.title2)
                                        .foregroundColor(primaryColor)
                                    Text("\(String(format: "%.2f", ingredient.amount)) \(ingredient.unit) \(ingredient.name)")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding(.horizontal) // 統一與其他 Section 的 padding
                        .padding(.vertical, 2) // 根據需要調整垂直間距
                    }

                    // 步驟
                    SectionView(title: "步驟") {
                        if let analyzedInstructions = recipe.analyzedInstructions, !analyzedInstructions.isEmpty {
                            ForEach(analyzedInstructions) { instruction in
                                VStack(alignment: .leading, spacing: 10) {
                                    if !instruction.name.isEmpty {
                                        Text(instruction.name)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(primaryColor)
                                    }

                                    ForEach(instruction.steps, id: \.number) { step in
                                        StepView(step: step)
                                    }
                                }
                                .padding(.bottom, 10)
                                .padding(.horizontal)
                            }
                        } else if let instructions = recipe.instructions?.htmlDecoded(), !instructions.isEmpty {
                            Text(instructions)
                                .font(.body)
                                .padding(.horizontal)
                        } else {
                            Text("沒有步驟資訊。")
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        }
                    }

                    // 進度指示器（可選）
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.3))
                            .edgesIgnoringSafeArea(.all)
                    }
                }
            }
            .padding(.horizontal)
            .background(backgroundColor.edgesIgnoringSafeArea(.all))
        }
        .onAppear {
            viewModel.getRecipeDetails(recipeId: recipeId)
        }
        .navigationBarTitle("食譜詳情", displayMode: .inline)
        // 添加 alert 來顯示錯誤訊息
        .alert(item: $viewModel.errorMessage) { errorMessage in
            Alert(
                title: Text("錯誤"),
                message: Text(errorMessage.message),
                dismissButton: .default(Text("確定")) {
                    viewModel.errorMessage = nil
                }
            )
        }
    }

    // 將更新份量的邏輯提取出來
    private func updateServings() {
        if let newServings = Int(inputServings), newServings > 0 {
            viewModel.adjustServings(newServings: newServings)
        } else {
            viewModel.errorMessage = ErrorMessage(message: "請輸入有效的份量。")
        }
    }
}

// 新增一個 CategorySectionView，用於顯示分類項目
struct CategorySectionView: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.gray)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) { // 修改間距為8
                    ForEach(items, id: \.self) { item in
                        TagView(text: item)
                    }
                }
                .padding(.vertical, 1)
            }
        }
        .padding(.horizontal, 0) // 減少左右 padding
    }
}

// 定義一個 TagView，用於顯示每個項目
struct TagView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange, Color.yellow]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
    }
}

// 預覽
struct RecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeDetailView(recipeId: 1)
            .environmentObject(RecipeSearchViewModel())
    }
}
