//
//  RecommendedRecipeCardView.swift
//  food
//
//  Created by Abu Anwar MD Abdullah on 25/1/21.
//
import SwiftUI

struct RecipeCollectionView: View {
    let recipe: Recipe
    let toggleFavorite: () -> Void
    
    @State private var animate = false

    var body: some View {
        HStack {
            // 判斷是否有圖片 URL，否則顯示系統圖片
            if let imageUrl = recipe.image, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .cornerRadius(18.0)
                        .shadow(radius: 5)
                        .padding(.trailing, 4)
                } placeholder: {
                    ProgressView() // 圖片加載時顯示進度條
                        .frame(width: 80, height: 80)
                }
            } else {
                // 使用系統圖片作為佔位符
                Image("RecipeFood")
                    .resizable()
                    .scaledToFill()
                    .aspectRatio(1, contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .cornerRadius(18.0)
                    .shadow(radius: 5)
                    .padding(.trailing, 4)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // 食譜類型
                if let dishType = recipe.dishTypes.first {
                    Text(dishType)
                        .font(.caption2)
                        .foregroundColor(Color(#colorLiteral(red: 0, green: 0.6272217631, blue: 0.7377799153, alpha: 1)))
                } else {
                    Text("Unknown Type")
                        .font(.caption2)
                        .foregroundColor(Color.gray)
                }
                
                // 食譜標題
                Text(recipe.title)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                // 食譜詳細資訊
                HStack {
                    Image(systemName: "person.2")
                        .resizable()
                        .frame(width: 17, height: 15)
                        .foregroundColor(Color("GrayColor"))
                    
                    Text("\(recipe.servings) Serving")
                        .font(.caption2)
                        .foregroundColor(Color("GrayColor"))
                    
                    Image(systemName: "clock")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .foregroundColor(Color("GrayColor"))
                        .padding(.leading)
                    
                    Text("\(recipe.readyInMinutes) mins")
                        .font(.caption2)
                        .foregroundColor(Color("GrayColor"))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 收藏按鈕
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    toggleFavorite()
                    animate = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    animate = false
                }
            }) {
                Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                    .foregroundColor((recipe.isFavorite) ? (Color(UIColor(named: "NavigationBarTitle") ?? UIColor.orange)) : Color.gray)
                    .scaleEffect(animate ? 1.5 : 1.0)
                    .opacity(animate ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: animate)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.2))
        .cornerRadius(18.0)
        .shadow(radius: 5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RecipeCollectionView_Previews: PreviewProvider {
    static let sampleRecipe = Recipe(
        id: 999,
        title: "Find more Favorite Recipe!",
        image: nil,
        servings: 2,
        readyInMinutes: 15,
        summary: "Get more Favorites.",
        isFavorite: false,
        dishTypes: ["Breakfast"]
    )
    
    static var previews: some View {
        NavigationView {
            NavigationLink(destination: RecipeMainView(showEditAndAddButtons: false)) {
                RecipeCollectionView(recipe: sampleRecipe, toggleFavorite: {})
            }
        }
    }
}
