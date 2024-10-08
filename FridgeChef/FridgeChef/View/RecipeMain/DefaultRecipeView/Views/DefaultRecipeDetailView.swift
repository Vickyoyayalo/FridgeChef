//
//  DefaultRecipeDetailView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/06.
//
//
import SwiftUI

struct DefaultRecipeDetailView: View {
    var recipe: DefaultRecipe
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView{
            ZStack {
                // 背景渐变
                LinearGradient(
                    gradient: Gradient(colors: [Color.yellow, Color.orange]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading) {
                        VStack {
                            Image(recipe.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: 200)
//                                .padding(10)
                                .shadow(color: Color.black.opacity(0.3), radius: 4, x:0, y: 4)
                        }
//                        .background(.white.opacity(0.5))
                        .cornerRadius(15)
                        .padding()
                        
                        Text(recipe.headline)
                            .foregroundColor(Color(UIColor(named: "SecondaryColor") ?? UIColor.blue))
                            .font(.custom("ArialRoundedMTBold", size: 20))
                            .padding(.horizontal)
                        
                        Text(recipe.title)
                            .font(.custom("ArialRoundedMTBold", size: 25))
                            .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange))
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading) {
                            VStack(alignment: .leading) {
                                Text("Instructions:")
                                    .font(.custom("ArialRoundedMTBold", size: 20))
                                    .padding(.vertical, 5)
                                Text(recipe.instructions)
                                    .font(.body)
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            .frame(maxHeight: .infinity, alignment: .top)
                            .padding()
                            
                            VStack(alignment: .leading) {
                                Text("Ingredients:")
                                    .font(.custom("ArialRoundedMTBold", size: 20))
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: -20) {
                                        ForEach(Array(recipe.ingredients.enumerated()), id: \.element) { index, ingredinet in
                                            Text(ingredinet)
                                                .foregroundColor(.white)
                                                .padding(10)
                                                .background(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange).opacity(0.7))
                                            
                                                .cornerRadius(6)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                .frame(height: 100)
                            }
                        }
//                        .frame(width: .infinity, height: 500, alignment: .bottomLeading)
                        .background(.white.opacity(0.5))
                        .cornerRadius(30, corners: [.topLeft, .topRight])
                    }
                }
                .background(.white.opacity(0.4))
                .navigationTitle(recipe.headline)
                .navigationBarItems(trailing:
                    Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange).opacity(0.7))
                    .onTapGesture {
                        dismiss()
                    })
            }
        }
    }
}


struct DefaultRecipeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DefaultRecipeDetailView(recipe: DefaultRecipe(title: "Classic Margherita Pizza", headline: "Lunch",
               ingredients: ["Pizza dough", "Tomatoes", "Fresh mozzarella", "Basil", "Olive oil"],
               instructions: " 1. Start by preheating your oven to its highest temperature. \n 2. Roll out the pizza dough into your desired shape. \n3. Spread a thin layer of crushed tomatoes over the dough, leaving a border around the edges. \n 4. Tear the fresh mozzarella into small pieces and distribute them evenly over the tomatoes. Sprinkle fresh basil leaves on top. ",
               imageName: "confessional"))
    }
}

//import SwiftUI
//
//struct DefaultRecipeDetailView: View {
//    let recipeId: Int
//    @EnvironmentObject var viewModel: RecipeSearchViewModel
//    @EnvironmentObject var foodItemStore: FoodItemStore
//
//    var body: some View {
//        VStack {
//            if viewModel.isLoading {
//                Spacer()
//                ProgressView()
//                    .scaleEffect(1.5)
//                Spacer()
//            } else if let recipe = viewModel.selectedRecipe, recipe.id == recipeId {
//                ScrollView {
//                    VStack(alignment: .leading, spacing: 20) {
//                        if let imageUrl = recipe.image, !imageUrl.isEmpty {
//                            AsyncImage(url: URL(string: imageUrl)) { image in
//                                image
//                                    .resizable()
//                                    .scaledToFit()
//                            } placeholder: {
//                                ProgressView()
//                            }
//                            .frame(maxWidth: .infinity)
//                        }
//
//                        Text(recipe.title)
//                            .font(.largeTitle)
//                            .fontWeight(.bold)
//
//                        HStack {
//                            Text("Servings: \(recipe.servings)")
//                            Spacer()
//                            Text("Ready in \(recipe.readyInMinutes) mins")
//                        }
//                        .font(.subheadline)
//                        .foregroundColor(.gray)
//
//                        if let summary = recipe.summary {
//                            Text(summary)
//                                .font(.body)
//                        }
//
//                        if let instructions = recipe.instructions {
//                            Text("Instructions")
//                                .font(.title2)
//                                .fontWeight(.semibold)
//
//                            Text(instructions)
//                                .font(.body)
//                        }
//
//                        // 添加更多詳細信息，如食材、步驟等
//
//                        Spacer()
//                    }
//                    .padding()
//                }
//            } else if let errorMessage = viewModel.errorMessage {
//                Spacer()
//                Text("錯誤：\(errorMessage.message)")
//                    .foregroundColor(.red)
//                    .padding()
//                Spacer()
//            } else {
//                Spacer()
//                Text("無法顯示食譜詳細信息。")
//                    .foregroundColor(.gray)
//                Spacer()
//            }
//        }
//        .navigationTitle("食譜詳情")
//        .onAppear {
//            viewModel.getRecipeDetails(recipeId: recipeId)
//        }
//        .alert(item: $viewModel.errorMessage) { errorMessage in
//            Alert(
//                title: Text("錯誤"),
//                message: Text(errorMessage.message),
//                dismissButton: .default(Text("確定")) {
//                    viewModel.errorMessage = nil
//                }
//            )
//        }
//    }
//}
//
//struct DefaultRecipeDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        RecipeDetailView(recipeId: 1)
//            .environmentObject(RecipeSearchViewModel())
//            .environmentObject(FoodItemStore())
//    }
//}
