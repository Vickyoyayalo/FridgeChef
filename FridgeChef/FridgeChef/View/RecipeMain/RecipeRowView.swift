//
//  RecipeRowView.swift
//  FridgeChef
//
//  Created by Vickyhereiam on 2024/9/27.
//

import SwiftUI

struct RecipeRowView: View {
    let recipe: Recipe
    let toggleFavorite: () -> Void
    @State private var animate = false
    @ObservedObject var viewModel: RecipeSearchViewModel

    var body: some View {
        VStack(alignment: .leading) {
            // 图片处理
            if let imageUrl = recipe.image, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: 200)
                            .background(Color(.systemGray5))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: 200)
                            .clipped()
                    case .failure:
                        Image("RecipeFood")
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: 200)
                            .foregroundColor(.gray)
                            .background(Color(.systemGray5))
                    @unknown default:
                        EmptyView()
                    }
                }
                .cornerRadius(10)
                .shadow(radius: 5)
            } else {
                Image(systemName: "RecipeFood")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .foregroundColor(.gray)
                    .background(Color(.clear))
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }

            // 食谱标题和收藏按钮
            HStack {
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(recipe.dishTypes.prefix(2).map { $0.capitalized }.joined(separator: ", "))
                        .foregroundColor(Color(UIColor(named: "SecondaryColor") ?? UIColor.blue))
                        .font(.custom("ArialRoundedMTBold", size: 15))
                        .padding(.leading, 20)
                        
                    Text(recipe.title)
                        .font(.custom("ArialRoundedMTBold", size: 20))
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 20)
                }

                Spacer()

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
                        .foregroundColor(Color(UIColor(named: recipe.isFavorite ? "NavigationBarTitle" : "GrayColor") ?? UIColor.gray))
                        .scaleEffect(animate ? 1.5 : 1.0)
                        .opacity(animate ? 0.5 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: animate)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 20) // 添加右侧内边距
            }
            .padding(.vertical) // 添加上下内边距
        }
        .listRowBackground(Color.clear)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.7))
        )
        .padding(.horizontal) // 添加左右内边距
        .padding(.vertical, 5) // 添加上下内边距，使每个 cell 有间距
        .shadow(radius: 5)
    }
}
struct RecipeRowView_Previews: PreviewProvider {
    static var previews: some View {
        RecipeRowView(
            recipe: Recipe(
                id: 1,
                title: "Sample Recipe",
                image: "RecipeFood",
                servings: 1,
                readyInMinutes: 0,
                summary: "Sample",
                isFavorite: false,
                dishTypes: ["Breakfast"]
            ),
            toggleFavorite: {},
            viewModel: RecipeSearchViewModel()
        )
    }
}
