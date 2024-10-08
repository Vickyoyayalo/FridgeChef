//
//  RecipeCardView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/10/6.
//

//import SwiftUI
//
//struct RecipeCardView: View {
//    let recipe: Recipe
//    
//    var body: some View {
//        VStack {
//            if let imageName = recipe.image, !imageName.isEmpty {
//                Image(imageName)
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: 150, height: 100)
//                    .clipped()
//                    .cornerRadius(10)
//            } else {
//                Rectangle()
//                    .fill(Color.gray.opacity(0.3))
//                    .frame(width: 150, height: 100)
//                    .cornerRadius(10)
//                    .overlay(
//                        Text("No Image")
//                            .foregroundColor(.gray)
//                    )
//            }
//            
//            Text(recipe.title)
//                .font(.headline)
//                .lineLimit(2)
//                .multilineTextAlignment(.center)
//                .padding([.leading, .trailing, .bottom], 5)
//        }
//        .background(Color.white)
//        .opacity(0.7)
//        .cornerRadius(10)
//        .shadow(radius: 5)
//    }
//}
//
//struct RecipeCardView_Previews: PreviewProvider {
//    static var previews: some View {
//        RecipeCardView(recipe: Recipe(id: 1, title: "示例食譜", image: "recipeImage", servings: 4, readyInMinutes: 30, summary: "這是一個示例食譜。", dishTypes: ["主菜"]))
//            .previewLayout(.sizeThatFits)
//    }
//}
//
